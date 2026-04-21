<template>
  <view class="page">
    <view class="glow glow-a"></view>
    <view class="glow glow-b"></view>

    <view class="hero card">
      <view class="hero-kicker">AERO OPERATIONS CANVAS</view>
      <view class="hero-title">航班控制塔</view>
      <view class="hero-desc">绑定当前航班后即可进入餐食预选流程。</view>
      <view class="hero-grid">
        <view class="hero-stat">
          <view class="num">{{ candidateFlights.length }}</view>
          <view class="txt">可选航班</view>
        </view>
        <view class="hero-stat">
          <view class="num">{{ currentFlight ? 'READY' : 'WAIT' }}</view>
          <view class="txt">当前状态</view>
        </view>
      </view>
    </view>

    <view class="rating card" v-if="pendingRatingList.length">
      <view>
        <view class="rating-title">你有 {{ pendingRatingList.length }} 条航后评分待完成</view>
        <view class="rating-desc">仅在航班结束后出现，完成后将优化推荐策略。</view>
      </view>
      <button class="rating-btn" @click="openRatingPage">去评分</button>
    </view>

    <view class="card startup" v-if="!user.idNumber">
      <view class="title">身份冷启动</view>
      <view class="tip">请输入身份证号，系统将自动匹配可乘坐航班。</view>
      <input v-model="idNumberInput" maxlength="18" placeholder="请输入18位身份证号" class="input" />
      <view class="tip">请选择舱型</view>
      <picker mode="selector" :range="cabinTypeOptions" range-key="label" :value="cabinTypeIndex" @change="onCabinTypeChange">
        <view class="input">{{ cabinTypeLabel }}</view>
      </picker>
      <view class="tip">规则：头等舱包含商务舱与经济舱餐食，商务舱包含经济舱餐食。</view>
      <button class="btn" @click="saveIdNumberAndLoad">保存并匹配</button>
    </view>

    <view class="card" v-else>
      <view class="section-head">
        <view class="title">身份信息</view>
        <view class="badge ok">已核验</view>
      </view>
      <view class="row"><text class="label">身份证：</text><text class="value">{{ user.idNumber }}</text></view>
      <view class="row"><text class="label">昵称：</text><text class="value">{{ user.name || '未设置' }}</text></view>
      <view class="row"><text class="label">舱型：</text><text class="value">{{ cabinTypeLabel }}</text></view>
      <view class="tip">如舱位变更，可在此重新设置并保存。</view>
      <picker mode="selector" :range="cabinTypeOptions" range-key="label" :value="cabinTypeIndex" @change="onCabinTypeChange">
        <view class="input">{{ cabinTypeLabel }}</view>
      </picker>
      <view class="tip">规则：头等舱包含商务舱与经济舱餐食，商务舱包含经济舱餐食。</view>
      <button class="btn" @click="saveCabinType">保存舱型</button>
    </view>

    <view class="card current-flight" v-if="currentFlight">
      <view class="section-head">
        <view class="title">当前主航班</view>
        <view class="badge">已绑定</view>
      </view>
      <view class="flight-no">{{ currentFlight.flightNumber }}</view>
      <view class="route">{{ currentFlight.departure }} -> {{ currentFlight.destination }}</view>
      <view class="meta-row">
        <view class="meta-item">供餐次数：{{ currentFlight.mealCount || '-' }}</view>
        <view class="meta-item" v-if="currentFlight.selectionDeadline">截止：{{ String(currentFlight.selectionDeadline).replace('T', ' ').slice(0, 16) }}</view>
        <view class="meta-item">预选状态：{{ selectionStatusText }}</view>
      </view>
      <button class="btn cta" @click="goRecommendation">进入餐食预选</button>
    </view>

    <view class="card">
      <view class="section-head">
        <view class="title">可选航班列表</view>
        <view class="sub-tip" v-if="loading">同步中...</view>
      </view>
      <view class="empty-box" v-if="!loading && candidateFlights.length === 0">
        <view class="empty-title">暂无可选航班</view>
        <view class="empty-desc">请核对身份证或联系地面工作人员处理。</view>
      </view>
      <view class="flight-item" v-for="item in candidateFlights" :key="item.id">
        <view class="flight-main">
          <view class="flight-no">{{ item.flightNumber }}</view>
          <view class="route">{{ item.departure }} -> {{ item.destination }}</view>
        </view>
        <button class="choose-btn" :class="{ active: currentFlight && currentFlight.id === item.id }" @click="selectFlight(item.id)">
          {{ currentFlight && currentFlight.id === item.id ? '已选择' : '选择' }}
        </button>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { bindFlightAPI, getCurrentFlightAPI, getFlightListAPI } from '@/api/flight'
import { getPendingRatingAPI, getRecommendationHistoryAPI } from '@/api/recommendation'
import { getUserInfoAPI, updateUserAPI } from '@/api/user'
import { useAuthGuard } from '@/composables/useAuthGuard'
import type { FlightInfo, PendingRatingInfo } from '@/types/aviation'
import type { ProfileDetail } from '@/types/user'

const {userStore, ensureLogin} = useAuthGuard()
const user = ref<ProfileDetail>({id: 0, openid: ''})
const idNumberInput = ref('')
const currentFlight = ref<FlightInfo | null>(null)
const candidateFlights = ref<FlightInfo[]>([])
const recommendationHistory = ref<Record<string, unknown>[]>([])
const pendingRatingList = ref<PendingRatingInfo[]>([])
const loading = ref(false)
const cabinTypeInput = ref(3)

const cabinTypeOptions = [
  { value: 1, label: '头等舱' },
  { value: 2, label: '商务舱' },
  { value: 3, label: '经济舱' },
]

const cabinTypeIndex = computed(() => {
  const idx = cabinTypeOptions.findIndex((item) => item.value === cabinTypeInput.value)
  return idx >= 0 ? idx : 2
})

const cabinTypeLabel = computed(() => {
  const current = cabinTypeOptions.find((item) => item.value === cabinTypeInput.value)
  return current?.label || '经济舱'
})

const onCabinTypeChange = (event: any) => {
  const index = Number(event.detail.value)
  const selected = cabinTypeOptions[index]
  if (!selected) return
  cabinTypeInput.value = selected.value
}

const normalizeCabinType = (value?: number | null) => {
  if (value === 1 || value === 2 || value === 3) {
    return value
  }
  return 3
}

const isSelectionClosed = () => {
  const deadline = currentFlight.value?.selectionDeadline
  if (!deadline) return false
  const timestamp = new Date(String(deadline)).getTime()
  if (Number.isNaN(timestamp)) return false
  return Date.now() > timestamp
}

const hasManualSelectionForCurrentFlight = () => {
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
}

const selectionStatusText = computed(() => {
  if (!currentFlight.value) return '未选择航班'
  if (!isSelectionClosed()) {
    return hasManualSelectionForCurrentFlight() ? '已预选（截止前可修改）' : '未预选（截止前可选择）'
  }
  return hasManualSelectionForCurrentFlight() ? '已预选，等待系统配餐' : '未预选，系统将自动配餐'
})

const isValidIdCard = (value: string) => {
  return /^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[0-9Xx]$/.test(value)
}

const loadCurrentFlight = async () => {
  const res = await getCurrentFlightAPI()
  currentFlight.value = res.data || null
}

const loadCandidates = async (idNumber?: string) => {
  const res = await getFlightListAPI(idNumber || user.value.idNumber)
  candidateFlights.value = res.data || []
}

const loadSelectionHistory = async () => {
  const res = await getRecommendationHistoryAPI()
  recommendationHistory.value = res.data || []
}

const loadPageData = async () => {
  if (!ensureLogin()) return
  loading.value = true
  try {
    const res = await getUserInfoAPI(userStore.profile!.id)
    user.value = res.data || {id: 0, openid: ''}
    idNumberInput.value = user.value.idNumber || ''
    cabinTypeInput.value = normalizeCabinType(user.value.cabinType)
    if (user.value.idNumber) {
      await Promise.all([loadCurrentFlight(), loadCandidates(), loadSelectionHistory()])
      const pendingRes = await getPendingRatingAPI()
      pendingRatingList.value = pendingRes.data || []
    } else {
      currentFlight.value = null
      candidateFlights.value = []
      recommendationHistory.value = []
      pendingRatingList.value = []
    }
  } finally {
    loading.value = false
  }
}

const saveIdNumberAndLoad = async () => {
  if (!ensureLogin()) return
  const value = idNumberInput.value.trim()
  if (!isValidIdCard(value)) {
    uni.showToast({title: '身份证号格式不正确', icon: 'none'})
    return
  }
  await updateUserAPI({
    id: userStore.profile!.id,
    idNumber: value,
    cabinType: normalizeCabinType(cabinTypeInput.value),
  })
  uni.showToast({title: '初始化成功', icon: 'none'})
  await loadPageData()
}

const saveCabinType = async () => {
  if (!ensureLogin()) return
  if (!user.value.idNumber) {
    uni.showToast({title: '请先完成身份证初始化', icon: 'none'})
    return
  }
  await updateUserAPI({
    id: userStore.profile!.id,
    cabinType: normalizeCabinType(cabinTypeInput.value),
  })
  uni.showToast({title: '舱型已更新', icon: 'none'})
  await loadPageData()
}

const selectFlight = async (flightId: number) => {
  await bindFlightAPI(flightId)
  uni.setStorageSync('identityVerified', '1')
  await loadCurrentFlight()
  uni.showToast({title: '已切换当前航班', icon: 'none'})
}

const goRecommendation = () => {
  uni.switchTab({url: '/pages/recommendation/recommendation'})
}

const openRatingPage = () => {
  if (!pendingRatingList.value.length) return
  uni.switchTab({url: '/pages/flightRating/flightRating'})
}

onShow(() => {
  void loadPageData()
})
</script>

<style scoped>
.page {
  --bg-a: #edf6ff;
  --bg-b: #f3fffa;
  --bg-c: #fff6ea;
  --ink-1: #132f4a;
  --ink-2: #4a6884;
  --line: #dbe8f5;
  --brand-1: #0c7fcd;
  --brand-2: #12a6de;
  --accent-1: #ffbf63;
  min-height: 100vh;
  padding: 24rpx;
  background: linear-gradient(158deg, var(--bg-a) 0%, var(--bg-b) 50%, var(--bg-c) 100%);
  font-family: 'DIN Alternate', 'Avenir Next', 'PingFang SC', sans-serif;
  position: relative;
  overflow: hidden;
}

.glow {
  position: absolute;
  border-radius: 999rpx;
  z-index: 0;
  opacity: 0.52;
  filter: blur(16rpx);
}

.glow-a {
  width: 280rpx;
  height: 280rpx;
  top: 120rpx;
  right: -90rpx;
  background: #7fd2ff;
}

.glow-b {
  width: 240rpx;
  height: 240rpx;
  left: -70rpx;
  bottom: 140rpx;
  background: #ffd79c;
}

.card {
  position: relative;
  z-index: 2;
  background: rgba(255, 255, 255, 0.94);
  border: 1px solid var(--line);
  border-radius: 30rpx;
  padding: 24rpx;
  margin-bottom: 18rpx;
  box-shadow: 0 20rpx 42rpx rgba(17, 56, 94, 0.1);
  animation: rise-in 380ms ease both;
}

.hero {
  background: linear-gradient(138deg, #0b76c2 0%, #1299d1 52%, #35b5dd 100%);
  border-color: rgba(255, 255, 255, 0.3);
  color: #fff;
}

.hero-kicker {
  font-size: 20rpx;
  letter-spacing: 2rpx;
  opacity: 0.9;
  margin-bottom: 4rpx;
}

.hero-title {
  font-size: 42rpx;
  font-weight: 800;
}

.hero-desc {
  margin-top: 8rpx;
  font-size: 24rpx;
  line-height: 1.8;
  opacity: 0.95;
}

.hero-grid {
  margin-top: 20rpx;
  display: flex;
  gap: 12rpx;
}

.hero-stat {
  flex: 1;
  border-radius: 16rpx;
  border: 1px solid rgba(255, 255, 255, 0.34);
  background: rgba(255, 255, 255, 0.2);
  padding: 12rpx;
}

.num {
  font-size: 32rpx;
  font-weight: 800;
}

.txt {
  margin-top: 4rpx;
  font-size: 22rpx;
}

.rating {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(128deg, #fff3dc 0%, #fff 46%, #ecf8ff 100%);
}

.rating-title {
  color: #1f3955;
  font-size: 29rpx;
  font-weight: 700;
}

.rating-desc {
  margin-top: 6rpx;
  color: #6f879f;
  font-size: 23rpx;
}

.rating-btn {
  width: 150rpx;
  height: 70rpx;
  line-height: 70rpx;
  border-radius: 35rpx;
  background: linear-gradient(135deg, #ffa535 0%, #f08322 100%);
  color: #fff;
  font-size: 26rpx;
}

.title {
  font-size: 31rpx;
  font-weight: 800;
  color: var(--ink-1);
}

.tip {
  margin-top: 8rpx;
  color: #6e8399;
  line-height: 1.8;
  font-size: 24rpx;
}

.input {
  margin-top: 14rpx;
  border: 1px solid #d4e2f2;
  border-radius: 14rpx;
  padding: 16rpx;
  background: #fbfdff;
}

.btn {
  margin-top: 14rpx;
  border-radius: 16rpx;
  background: linear-gradient(135deg, var(--brand-1) 0%, var(--brand-2) 100%);
  color: #fff;
  font-size: 26rpx;
}

.btn.cta {
  margin-top: 16rpx;
}

.section-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8rpx;
}

.badge {
  padding: 8rpx 14rpx;
  border-radius: 999rpx;
  background: #e7f5ff;
  color: var(--brand-1);
  font-size: 22rpx;
}

.badge.ok {
  background: #e8f8ef;
  color: #2a9d64;
}

.row {
  margin-top: 8rpx;
  font-size: 25rpx;
}

.label {
  color: #6f879f;
}

.value {
  color: #2a4a67;
}

.flight-no {
  font-size: 33rpx;
  font-weight: 800;
  color: #15334f;
}

.route {
  margin-top: 8rpx;
  color: #42617f;
  font-size: 26rpx;
}

.meta-row {
  margin-top: 10rpx;
}

.meta-item {
  margin-top: 6rpx;
  color: #5d7894;
  font-size: 24rpx;
}

.sub-tip {
  color: #788ea5;
  font-size: 23rpx;
}

.empty-box {
  border: 1px dashed #c9dcec;
  border-radius: 14rpx;
  background: #fafcff;
  padding: 20rpx;
}

.empty-title {
  color: #23445f;
  font-size: 28rpx;
  font-weight: 700;
}

.empty-desc {
  margin-top: 6rpx;
  color: #7892aa;
  font-size: 24rpx;
}

.flight-item {
  margin-top: 12rpx;
  border: 1px solid #e1edf8;
  border-radius: 18rpx;
  background: linear-gradient(145deg, #ffffff 0%, #f7fbff 100%);
  padding: 16rpx;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.flight-main {
  flex: 1;
}

.choose-btn {
  width: 140rpx;
  height: 64rpx;
  line-height: 64rpx;
  border-radius: 32rpx;
  color: var(--brand-1);
  font-size: 24rpx;
  background: #edf8ff;
}

.choose-btn.active {
  color: #fff;
  background: linear-gradient(135deg, var(--brand-1) 0%, var(--brand-2) 100%);
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
