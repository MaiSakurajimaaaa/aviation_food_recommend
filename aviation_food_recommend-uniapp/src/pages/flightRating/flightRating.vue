<template>
  <view class="page">
    <view class="bg-orb orb-1"></view>
    <view class="bg-orb orb-2"></view>

    <view class="rating-card" v-if="!selected && pendingList.length">
      <view class="card-head">
        <text class="badge">待评分列表</text>
        <text class="headline">请选择需要评价的航班</text>
        <text class="subline">你的评分将用于优化餐食推荐与航旅服务</text>
        <view class="count-pill">共 {{ pendingList.length }} 条</view>
      </view>

      <view class="list-wrap">
        <view class="flight-item" v-for="item in pendingList" :key="item.flightId">
          <view class="flight-meta">
            <view class="flight-no">{{ item.flightNumber || '当前航班' }}</view>
            <view class="route">{{ `${item.departure || '-'} -> ${item.destination || '-'}` }}</view>
            <view class="time" v-if="item.arrivalTime">到达时间：{{ formatTime(item.arrivalTime) }}</view>
          </view>
          <button class="mini-btn" @click="enterRating(item)">去评分</button>
        </view>
      </view>
    </view>

    <view class="rating-card" v-else-if="selected">
      <view class="card-head">
        <text class="badge">航后反馈</text>
        <text class="headline">本次航班体验如何？</text>
        <text class="subline">请对本次服务质量进行评分</text>
      </view>

      <view class="flight-brief">
        <view class="flight-no">{{ selected.flightNumber || '当前航班' }}</view>
        <view class="route">{{ `${selected.departure || '-'} -> ${selected.destination || '-'}` }}</view>
        <view class="time" v-if="selected.arrivalTime">到达时间：{{ formatTime(selected.arrivalTime) }}</view>
      </view>

      <view class="score-area">
        <view class="score-title">请打分（满分五星）</view>
        <view class="stars">
          <view
            class="star-btn"
            :class="{ active: rating >= star }"
            v-for="star in [1, 2, 3, 4, 5]"
            :key="star"
            @click="rating = star"
          >
            ★
          </view>
        </view>
        <view class="score-tip">{{ ratingLabel }}</view>
      </view>

      <view class="actions">
        <button class="btn ghost" :disabled="submitting" @click="backToList">返回列表</button>
        <button class="btn ghost" :disabled="submitting" @click="skipNow">稍后再评</button>
        <button class="btn" :disabled="submitting" @click="submitRating">{{ submitting ? '提交中...' : '立即提交' }}</button>
      </view>
    </view>

    <view class="rating-card" v-else>
      <view class="headline done">当前没有待评分航班</view>
      <view class="subline">感谢你的使用，祝你旅途愉快。</view>
      <button class="btn back" @click="goBack">返回我的</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import { deferRecommendationAPI, getPendingRatingAPI, rateRecommendationAPI } from '@/api/recommendation'
import type { PendingRatingInfo } from '@/types/aviation'

const pendingList = ref<PendingRatingInfo[]>([])
const selected = ref<PendingRatingInfo | null>(null)
const rating = ref(5)
const submitting = ref(false)

const ratingLabel = computed(() => {
  const map: Record<number, string> = {
    1: '1星：较不满意',
    2: '2星：有待改进',
    3: '3星：整体一般',
    4: '4星：比较满意',
    5: '5星：非常满意',
  }
  return map[rating.value] || '请选择评分'
})

const formatTime = (value?: string) => {
  if (!value) return '-'
  return String(value).replace('T', ' ').slice(0, 16)
}

const loadPending = async (payload?: PendingRatingInfo | null) => {
  if (payload) {
    pendingList.value = [payload]
    return
  }
  const res = await getPendingRatingAPI()
  pendingList.value = res.data || []
}

const enterRating = (item: PendingRatingInfo) => {
  selected.value = item
  rating.value = 5
}

const backToList = () => {
  selected.value = null
}

const removeRatedFlight = (flightId?: number) => {
  if (!flightId) return
  pendingList.value = pendingList.value.filter((item) => item.flightId !== flightId)
}

const submitRating = async () => {
  if (!selected.value?.flightId || submitting.value) return
  submitting.value = true
  try {
    await rateRecommendationAPI(rating.value, selected.value.flightId)
    removeRatedFlight(selected.value.flightId)
    selected.value = null
    uni.showToast({ title: '感谢评分，已提交', icon: 'none' })
  } catch (error) {
    const message = typeof error === 'object' && error && 'msg' in error
      ? String((error as { msg?: string }).msg || '评分提交失败')
      : '评分提交失败'
    uni.showToast({ title: message, icon: 'none' })
  } finally {
    submitting.value = false
  }
}

const skipNow = async () => {
  const flightId = selected.value?.flightId
  if (!flightId || submitting.value) return
  submitting.value = true
  try {
    await deferRecommendationAPI(flightId)
    selected.value = null
    removeRatedFlight(flightId)
    uni.showToast({ title: '已设置稍后提醒', icon: 'none' })
  } catch (error) {
    const message = typeof error === 'object' && error && 'msg' in error
      ? String((error as { msg?: string }).msg || '延期失败')
      : '延期失败'
    uni.showToast({ title: message, icon: 'none' })
  } finally {
    submitting.value = false
  }
}

const goBack = () => {
  uni.switchTab({ url: '/pages/my/my' })
}

onLoad((options) => {
  try {
    const payloadRaw = options?.payload ? decodeURIComponent(options.payload) : ''
    const parsed = payloadRaw ? JSON.parse(payloadRaw) as PendingRatingInfo | PendingRatingInfo[] : null
    if (Array.isArray(parsed)) {
      pendingList.value = parsed
      return
    }
    void loadPending(parsed)
  } catch {
    void loadPending(null)
  }
})

onShow(() => {
  selected.value = null
  void loadPending(null)
})
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 28rpx;
  background: radial-gradient(circle at 20% 10%, #ffe8ce 0%, transparent 40%),
              radial-gradient(circle at 85% 15%, #c8eeff 0%, transparent 35%),
              linear-gradient(165deg, #fff8ef 0%, #eef8ff 60%, #e8f0ff 100%);
  position: relative;
  overflow: hidden;
}

.bg-orb {
  position: absolute;
  border-radius: 999rpx;
  filter: blur(6rpx);
  opacity: 0.36;
}

.orb-1 {
  width: 220rpx;
  height: 220rpx;
  right: -40rpx;
  top: 180rpx;
  background: #ffd36c;
}

.orb-2 {
  width: 260rpx;
  height: 260rpx;
  left: -70rpx;
  bottom: 120rpx;
  background: #7acfff;
}

.rating-card {
  position: relative;
  z-index: 2;
  margin-top: 80rpx;
  background: rgba(255, 255, 255, 0.92);
  border: 1px solid rgba(255, 255, 255, 0.65);
  border-radius: 28rpx;
  padding: 34rpx 30rpx;
  box-shadow: 0 18rpx 42rpx rgba(18, 58, 92, 0.14);
  backdrop-filter: blur(6rpx);
}

.list-wrap {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}

.flight-item {
  border-radius: 20rpx;
  background: linear-gradient(140deg, #edf7ff 0%, #fff6ea 100%);
  border: 1px solid #e2edf7;
  padding: 18rpx;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12rpx;
  box-shadow: 0 8rpx 16rpx rgba(26, 66, 102, 0.08);
}

.flight-meta {
  flex: 1;
}

.mini-btn {
  min-width: 138rpx;
  height: 64rpx;
  line-height: 64rpx;
  border-radius: 12rpx;
  background: linear-gradient(135deg, #1f8ad8 0%, #0aa5de 100%);
  color: #fff;
  font-size: 24rpx;
  box-shadow: 0 10rpx 16rpx rgba(10, 123, 198, 0.25);
}

.mini-btn::after {
  border: none;
}

.card-head {
  margin-bottom: 24rpx;
}

.count-pill {
  margin-top: 14rpx;
  display: inline-block;
  font-size: 22rpx;
  color: #356084;
  background: #eaf4ff;
  border: 1px solid #d4e8fb;
  border-radius: 999rpx;
  padding: 6rpx 14rpx;
}

.badge {
  display: inline-flex;
  padding: 6rpx 14rpx;
  border-radius: 999rpx;
  background: #17324d;
  color: #fff4df;
  font-size: 22rpx;
  letter-spacing: 1rpx;
}

.headline {
  margin-top: 14rpx;
  display: block;
  font-size: 42rpx;
  font-weight: 800;
  color: #1f3952;
  line-height: 1.3;
}

.headline.done {
  font-size: 34rpx;
  margin-top: 6rpx;
}

.subline {
  margin-top: 8rpx;
  display: block;
  color: #5f7287;
  font-size: 24rpx;
  line-height: 1.7;
}

.flight-brief {
  border-radius: 20rpx;
  background: linear-gradient(140deg, #edf7ff 0%, #fff6ea 100%);
  padding: 20rpx;
  border: 1px solid #e2edf7;
}

.flight-no {
  font-size: 30rpx;
  color: #143a60;
  font-weight: 700;
}

.route {
  margin-top: 6rpx;
  color: #2f5b85;
  font-size: 26rpx;
}

.time {
  margin-top: 8rpx;
  font-size: 23rpx;
  color: #7589a0;
}

.score-area {
  margin-top: 24rpx;
  padding: 22rpx;
  border-radius: 20rpx;
  background: #fff;
  border: 1px solid #ebf1f7;
}

.score-title {
  font-size: 27rpx;
  font-weight: 700;
  color: #1d3852;
}

.stars {
  margin-top: 14rpx;
  display: flex;
  gap: 12rpx;
}

.star-btn {
  width: 76rpx;
  height: 76rpx;
  border-radius: 18rpx;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 42rpx;
  color: #c8d4e1;
  background: #f5f9fd;
  border: 1px solid #e2ebf4;
}

.star-btn.active {
  color: #ff9d00;
  background: #fff5df;
  border-color: #ffd48c;
  transform: translateY(-2rpx);
}

.score-tip {
  margin-top: 12rpx;
  font-size: 24rpx;
  color: #5f768f;
}

.actions {
  margin-top: 28rpx;
  display: flex;
  gap: 14rpx;
  flex-wrap: wrap;
}

.btn {
  flex: 1;
  border-radius: 14rpx;
  font-size: 28rpx;
  background: linear-gradient(135deg, #1f8ad8 0%, #0aa5de 100%);
  color: #fff;
}

.btn.ghost {
  background: #f4f8fc;
  color: #315673;
  border: 1px solid #d8e3ed;
}

.btn.back {
  margin-top: 20rpx;
}
</style>
