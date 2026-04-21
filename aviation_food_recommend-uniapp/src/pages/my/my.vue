<template>
  <view class="page">
    <view class="blur blur-a"></view>
    <view class="blur blur-b"></view>

    <view class="profile card">
      <image class="avatar" :src="user.pic || '/static/images/user_default.png'" mode="aspectFill"></image>
      <view class="profile-right">
        <view class="profile-kicker">AERO IDENTITY SUITE</view>
        <view class="name">{{ user.name || '未设置昵称' }}</view>
        <view class="sub">手机号 {{ user.phone || '未设置' }}</view>
        <view class="sub" v-if="loading">正在同步最新状态...</view>
        <view class="status-row">
          <view class="status-pill">{{ preferenceLoaded ? '画像已就绪' : '画像待完善' }}</view>
          <view class="status-pill" v-if="currentFlight">航班已绑定</view>
        </view>
      </view>
    </view>

    <view class="card rating-panel" v-if="pendingRatingList.length">
      <view>
        <view class="panel-title">航后评分待完成（{{ pendingRatingList.length }}）</view>
        <view class="panel-desc">仅航班结束后出现，完成评分可持续优化推荐质量。</view>
      </view>
      <button class="panel-btn" @click="openRatingPage(true)">立即评分</button>
    </view>

    <view class="card notice-panel" @click="goAnnouncementCenter">
      <view>
        <view class="panel-title">公告中心</view>
        <view class="panel-desc">{{ announcementUnread ? `你有 ${formatUnreadCount(announcementUnread)} 条未读公告` : '暂无未读公告，点击查看历史通知' }}</view>
      </view>
      <button class="panel-btn notice-btn">查看公告{{ announcementUnread ? `（${formatUnreadCount(announcementUnread)}）` : '' }}</button>
    </view>

    <view class="card">
      <view class="title">航班与预选</view>
      <view class="row"><text class="label">当前航班：</text><text>{{ currentFlightText }}</text></view>
      <view class="row status-wrap">
        <text class="label">预选状态：</text>
        <view class="status-detail">
          <view class="status-line-main">{{ selectionStatusTitle }}</view>
          <view class="status-chips">
            <text class="chip-tag">{{ selectionPickByFlightText }}</text>
            <text class="chip-tag">可改：{{ selectionEditableText }}</text>
            <text class="chip-tag">截止：{{ selectionDeadlineText }}</text>
          </view>
          <view class="status-line-sub">{{ selectionStatusNote }}</view>
        </view>
      </view>
      <view class="row"><text class="label">航后评分：</text><text>{{ ratingStatusText }}</text></view>
    </view>

    <view class="card">
      <view class="title">偏好画像</view>
      <view class="row"><text class="label">偏好状态：</text><text>{{ preferenceLoaded ? '已配置' : '未配置' }}</text></view>
      <view class="row" v-if="preference.flavorPreferences"><text class="label">口味：</text><text>{{ formatPreferenceArray(preference.flavorPreferences) }}</text></view>
      <view class="row" v-if="preference.mealTypePreferences"><text class="label">餐型：</text><text>{{ formatMealTypePreference(preference.mealTypePreferences) }}</text></view>
      <view class="row"><text class="label">标签：</text><text>{{ profileTagsText }}</text></view>
      <view class="tags" v-if="profileTags.length">
        <view class="tag" v-for="item in profileTags" :key="item">{{ item }}</view>
      </view>
      <view class="btn-row">
        <button class="btn" @click="goPreferences">编辑偏好</button>
        <button class="btn ghost" @click="goUpdate">编辑资料</button>
      </view>
    </view>

    <view class="card logout-card">
      <button class="logout" @click="logout">退出登录</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { getCurrentFlightAPI } from '@/api/flight'
import { getPreferenceAPI } from '@/api/preference'
import { getAnnouncementListAPI, getPendingRatingAPI, getRecommendationHistoryAPI } from '@/api/recommendation'
import { getProfileTagsAPI, getUserInfoAPI } from '@/api/user'
import { useAuthGuard } from '@/composables/useAuthGuard'
import { countUnreadAnnouncements, filterActiveAnnouncements, sortAnnouncementsByTime } from '@/utils/announcement'
import { mapMealTypeValues } from '@/utils/meal'
import type { AnnouncementItem, FlightInfo, PendingRatingInfo, UserPreference } from '@/types/aviation'
import type { ProfileDetail } from '@/types/user'

const {userStore, ensureLogin} = useAuthGuard()
const user = ref<ProfileDetail>({id: 0, openid: ''})
const currentFlight = ref<FlightInfo | null>(null)
const preference = ref<UserPreference>({})
const preferenceLoaded = ref(false)
const profileTags = ref<string[]>([])
const recommendationHistory = ref<Record<string, unknown>[]>([])
const pendingRatingList = ref<PendingRatingInfo[]>([])
const announcementUnread = ref(0)
const loading = ref(false)

const currentFlightText = computed(() => {
  if (!currentFlight.value) return '未选择'
  return `${currentFlight.value.flightNumber}（${currentFlight.value.departure} -> ${currentFlight.value.destination}）`
})

const profileTagsText = computed(() => {
  if (!profileTags.value.length) return '待完善偏好画像'
  return profileTags.value.join('、')
})

const isSelectionClosed = computed(() => {
  const deadline = currentFlight.value?.selectionDeadline
  if (!deadline) return false
  const timestamp = new Date(String(deadline)).getTime()
  if (Number.isNaN(timestamp)) return false
  return Date.now() > timestamp
})

const hasManualSelectionForCurrentFlight = computed(() => {
  const flightId = currentFlight.value?.id
  if (!flightId) return false
  return recommendationHistory.value.some((item) => {
    const row = item as Record<string, unknown>
    const rowFlightIdRaw = row.flightId ?? row.flight_id
    const rowFlightId = Number(rowFlightIdRaw)
    if (Number.isNaN(rowFlightId) || rowFlightId !== flightId) return false
    const feedback = String(row.userFeedback ?? row.user_feedback ?? '')
    return feedback.startsWith('MANUAL_SELECTED')
  })
})

const selectionPickByFlightText = computed(() => {
  const no = currentFlight.value?.flightNumber || '未绑定航班'
  const status = hasManualSelectionForCurrentFlight.value ? '已选' : '未选'
  return `${no}：${status}`
})

const selectionEditableText = computed(() => {
  if (!currentFlight.value) return '不可'
  if (isSelectionClosed.value) return '不可'
  return '可修改'
})

const selectionDeadlineText = computed(() => {
  if (!currentFlight.value?.selectionDeadline) return '未设置'
  const formatted = String(currentFlight.value.selectionDeadline).replace('T', ' ').slice(0, 16)
  return isSelectionClosed.value ? `${formatted}（已截止）` : formatted
})

const selectionStatusTitle = computed(() => {
  if (!currentFlight.value) return '当前未绑定航班'
  if (!isSelectionClosed.value) {
    return hasManualSelectionForCurrentFlight.value ? '当前航班已完成预选' : '当前航班尚未预选'
  }
  return hasManualSelectionForCurrentFlight.value ? '当前航班预选已锁定' : '当前航班未预选'
})

const selectionStatusNote = computed(() => {
  if (!currentFlight.value) return '建议先在航班页绑定主航班，再进入餐食预选。'
  if (!isSelectionClosed.value && !hasManualSelectionForCurrentFlight.value) {
    return '建议尽快完成预选，避免截止后转为系统自动分配。'
  }
  if (!isSelectionClosed.value && hasManualSelectionForCurrentFlight.value) {
    return '如需更换餐食，可在截止前前往“餐食预选”页再次确认。'
  }
  return '如需评价本次服务，请在“评分”页完成航后反馈。'
})

const ratingStatusText = computed(() => {
  if (pendingRatingList.value.length) return `待评分（${pendingRatingList.value.length} 条）`
  return '已完成或暂无待评分'
})

const formatUnreadCount = (count: number) => {
  if (count > 99) return '99+'
  return String(count)
}

const openRatingPage = (force = false) => {
  if (!force) return
  if (!pendingRatingList.value.length) return

  uni.switchTab({url: '/pages/flightRating/flightRating'})
}

const parseArray = (raw?: string) => {
  if (!raw) return [] as string[]
  try {
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) ? parsed.map((item) => String(item)) : [String(raw)]
  } catch {
    return [String(raw)]
  }
}

const formatPreferenceArray = (raw?: string) => {
  const values = parseArray(raw)
  return values.length ? values.join('、') : '-'
}

const formatMealTypePreference = (raw?: string) => {
  const values = parseArray(raw)
  if (!values.length) return '-'
  return mapMealTypeValues(values).join('、')
}

const loadData = async () => {
  if (!ensureLogin()) return
  loading.value = true
  try {
    const [userRes, flightRes, preferenceRes, tagsRes, historyRes, pendingRes, announcementRes] = await Promise.all([
      getUserInfoAPI(userStore.profile!.id),
      getCurrentFlightAPI(),
      getPreferenceAPI(),
      getProfileTagsAPI(),
      getRecommendationHistoryAPI(),
      getPendingRatingAPI(),
      getAnnouncementListAPI().catch(() => ({data: [] as AnnouncementItem[]})),
    ])
    user.value = userRes.data || {id: 0, openid: ''}
    currentFlight.value = flightRes.data || null
    preference.value = preferenceRes.data || {}
    preferenceLoaded.value = !!preferenceRes.data
    profileTags.value = tagsRes.data || []
    recommendationHistory.value = historyRes.data || []
    pendingRatingList.value = pendingRes.data || []
    const activeAnnouncements = sortAnnouncementsByTime(filterActiveAnnouncements(announcementRes.data || []))
    announcementUnread.value = countUnreadAnnouncements(activeAnnouncements)
    openRatingPage(false)
  } finally {
    loading.value = false
  }
}

const goPreferences = () => {
  uni.navigateTo({url: '/pages/preferences/preferences'})
}

const goUpdate = () => {
  uni.navigateTo({url: '/pages/updateMy/updateMy'})
}

const goAnnouncementCenter = () => {
  uni.navigateTo({url: '/pages/announcement/announcement'})
}

const logout = () => {
  userStore.clearProfile()
  uni.removeStorageSync('identityVerified')
  uni.reLaunch({url: '/pages/login/login'})
}

onShow(() => {
  void loadData()
})
</script>

<style scoped>
.page {
  --bg-a: #edf6ff;
  --bg-b: #f3fffa;
  --bg-c: #fff6ea;
  --ink-1: #132f4a;
  --line: #dbe8f5;
  --brand-1: #0c7fcd;
  --brand-2: #12a6de;
  min-height: 100vh;
  padding: 24rpx;
  background: linear-gradient(158deg, var(--bg-a) 0%, var(--bg-b) 50%, var(--bg-c) 100%);
  font-family: 'DIN Alternate', 'Avenir Next', 'PingFang SC', sans-serif;
  position: relative;
  overflow: hidden;
}

.blur {
  position: absolute;
  border-radius: 999rpx;
  z-index: 0;
  opacity: 0.52;
  filter: blur(16rpx);
}

.blur-a {
  width: 280rpx;
  height: 280rpx;
  right: -80rpx;
  top: 140rpx;
  background: #80d5ff;
}

.blur-b {
  width: 240rpx;
  height: 240rpx;
  left: -70rpx;
  bottom: 130rpx;
  background: #ffd9a4;
}

.card {
  position: relative;
  z-index: 2;
  background: rgba(255, 255, 255, 0.94);
  border-radius: 30rpx;
  border: 1px solid var(--line);
  padding: 24rpx;
  margin-bottom: 18rpx;
  box-shadow: 0 20rpx 42rpx rgba(17, 56, 94, 0.1);
  animation: rise-in 380ms ease both;
}

.profile {
  display: flex;
  align-items: center;
  gap: 16rpx;
  background: linear-gradient(138deg, #0b76c2 0%, #1299d1 52%, #35b5dd 100%);
  border-color: rgba(255, 255, 255, 0.3);
}

.profile-kicker {
  color: rgba(255, 255, 255, 0.9);
  font-size: 20rpx;
  letter-spacing: 2rpx;
  margin-bottom: 2rpx;
}

.avatar {
  width: 114rpx;
  height: 114rpx;
  border-radius: 50%;
  border: 3rpx solid rgba(255, 255, 255, 0.65);
}

.profile-right {
  flex: 1;
}

.name {
  color: #fff;
  font-size: 36rpx;
  font-weight: 800;
}

.sub {
  margin-top: 6rpx;
  color: rgba(255, 255, 255, 0.92);
  font-size: 23rpx;
}

.status-row {
  margin-top: 10rpx;
  display: flex;
  gap: 8rpx;
  flex-wrap: wrap;
}

.status-pill {
  padding: 6rpx 12rpx;
  border-radius: 999rpx;
  font-size: 21rpx;
  color: #fff;
  border: 1px solid rgba(255, 255, 255, 0.36);
  background: rgba(255, 255, 255, 0.2);
}

.rating-panel {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(130deg, #fff3dc 0%, #fff 48%, #ecf8ff 100%);
}

.notice-panel {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(130deg, #eef8ff 0%, #fff 46%, #fff5e6 100%);
}

.panel-title {
  color: #1e3a56;
  font-size: 30rpx;
  font-weight: 700;
}

.panel-desc {
  margin-top: 6rpx;
  color: #6a839b;
  font-size: 23rpx;
}

.panel-btn {
  width: 150rpx;
  height: 70rpx;
  line-height: 70rpx;
  border-radius: 35rpx;
  background: linear-gradient(135deg, #ffa936 0%, #f18220 100%);
  color: #fff;
  font-size: 26rpx;
}

.panel-btn.notice-btn {
  width: auto;
  min-width: 180rpx;
  padding: 0 20rpx;
  background: linear-gradient(135deg, #0d83cc 0%, #2db8e0 100%);
}

.title {
  color: var(--ink-1);
  font-size: 32rpx;
  font-weight: 800;
  margin-bottom: 10rpx;
}

.row {
  margin-top: 8rpx;
  color: #365573;
  font-size: 25rpx;
  line-height: 1.7;
}

.status-wrap {
  align-items: flex-start;
}

.status-detail {
  flex: 1;
}

.status-line-main {
  color: #1f3e5c;
  font-weight: 600;
  line-height: 1.5;
}

.status-chips {
  margin-top: 8rpx;
  display: flex;
  flex-wrap: wrap;
  gap: 8rpx;
}

.chip-tag {
  display: inline-flex;
  align-items: center;
  padding: 4rpx 12rpx;
  border-radius: 999rpx;
  font-size: 21rpx;
  color: #2e638f;
  border: 1px solid #d5e7f7;
  background: #f3f9ff;
}

.status-line-sub {
  margin-top: 8rpx;
  color: #6d8499;
  font-size: 22rpx;
  line-height: 1.6;
}

.label {
  color: #7189a2;
}

.tags {
  margin-top: 12rpx;
  display: flex;
  gap: 8rpx;
  flex-wrap: wrap;
}

.tag {
  padding: 6rpx 12rpx;
  border-radius: 999rpx;
  border: 1px solid #d5e5f4;
  color: #2f638f;
  font-size: 22rpx;
  background: #f5faff;
}

.btn-row {
  display: flex;
  gap: 12rpx;
  margin-top: 14rpx;
}

.btn {
  flex: 1;
  border-radius: 16rpx;
  background: linear-gradient(135deg, var(--brand-1) 0%, var(--brand-2) 100%);
  color: #fff;
  font-size: 26rpx;
}

.btn.ghost {
  background: #f1f6fb;
  border: 1px solid #d7e2ee;
  color: #50708b;
}

.logout-card {
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
}

.logout {
  border-radius: 16rpx;
  background: linear-gradient(135deg, #ff6d70 0%, #f64f57 100%);
  color: #fff;
  font-size: 28rpx;
}

@keyframes rise-in {
  from {
    opacity: 0;
    transform: translateY(12rpx);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
