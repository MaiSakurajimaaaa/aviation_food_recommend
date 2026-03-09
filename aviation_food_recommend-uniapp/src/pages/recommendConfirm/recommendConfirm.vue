<template>
  <view class="page">
    <view class="card hero">
      <view class="title">确认餐食预选</view>
      <view class="desc">请核对航班与推荐信息，提交后将写入本次航班预选记录</view>
    </view>

    <view class="card" v-if="meal">
      <view class="label">当前航班</view>
      <view class="value">{{ `${meal?.flightNumber || '-'}（${meal?.departure || '-'} → ${meal?.destination || '-'}）` }}</view>
      <view class="meta" v-if="meal?.selectionDeadline">预选截止：{{ formatDeadline(meal?.selectionDeadline) }}（截止前可修改）</view>
    </view>

    <view class="card" v-if="meal">
      <view class="label">餐食名称</view>
      <view class="value strong">{{ meal?.dishName || '-' }}</view>
      <view class="score-track">
        <view class="score-fill" :style="{ width: `${Math.round((meal?.score || 0) * 100)}%` }"></view>
      </view>
      <view class="meta">匹配度：{{ Math.round((meal?.score || 0) * 100) }}%</view>
      <view class="meta">餐型：{{ formatMealType(meal?.mealType) }}</view>
      <view class="meta">口味：{{ formatFlavor(meal?.flavorTags) }}</view>
      <view class="meta">推荐依据：{{ meal?.explainReason || '基础营养均衡推荐' }}</view>
      <view class="meta">降级层级：第 {{ (meal?.fallbackLevel ?? 0) + 1 }} 候选</view>
      <view class="detail">{{ meal?.detail || '营养均衡，适合航旅场景。' }}</view>
    </view>

    <view class="card empty-card" v-if="!meal">
      <view class="empty-title">缺少推荐数据</view>
      <view class="empty-desc">请返回推荐页重新选择餐食后再确认。</view>
      <button class="btn ghost" @click="goBack">返回重选</button>
    </view>

    <view class="actions card" v-if="meal">
      <button class="btn ghost" @click="goBack">返回重选</button>
      <button class="btn" :disabled="submitting" @click="confirmSelect">确认预选</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { selectRecommendationMealAPI } from '@/api/recommendation'
import type { RecommendConfirmPayload } from '@/types/aviation'

const meal = ref<RecommendConfirmPayload | null>(null)
const submitting = ref(false)

const formatMealType = (value?: number) => {
  const map: Record<number, string> = {
    1: '儿童餐',
    2: '标准餐',
    3: '清真餐',
    4: '素食餐',
  }
  return value ? map[value] || '标准餐' : '标准餐'
}

const formatFlavor = (value?: string) => {
  if (!value) return '清淡'
  return String(value).replace(/[\[\]"]/g, '')
}

const formatDeadline = (value?: string) => {
  if (!value) return '-'
  return String(value).replace('T', ' ').slice(0, 16)
}

onLoad((options) => {
  try {
    const payload = options?.payload ? decodeURIComponent(options.payload) : '{}'
    meal.value = JSON.parse(payload)
  } catch {
    meal.value = null
  }
})

const goBack = () => {
  uni.navigateBack()
}

const confirmSelect = async () => {
  if (!meal.value?.dishId) {
    uni.showToast({ title: '餐食数据异常', icon: 'none' })
    return
  }
  if (submitting.value) return
  submitting.value = true
  try {
    const result = await selectRecommendationMealAPI(meal.value.dishId)
    const message = result.data?.modified ? '改选成功（已更新）' : '预选成功'
    uni.showToast({ title: message, icon: 'none' })

    setTimeout(() => {
      uni.switchTab({ url: '/pages/my/my' })
    }, 300)
  } catch (error) {
    const message = typeof error === 'object' && error && 'msg' in error ? String((error as { msg?: string }).msg || '提交失败') : '提交失败'
    uni.showToast({ title: message, icon: 'none' })
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.page { padding: 24rpx; background: linear-gradient(180deg, #eef8ff 0%, #f7fbff 100%); min-height: 100vh; }
.card { background: #fff; border-radius: 18rpx; padding: 24rpx; margin-bottom: 16rpx; box-shadow: 0 8rpx 20rpx rgba(34, 170, 238, 0.08); }
.hero { background: linear-gradient(135deg, #00aaff 0%, #59c7ff 100%); color: #fff; }
.title { font-size: 32rpx; font-weight: 700; }
.desc { margin-top: 8rpx; font-size: 24rpx; opacity: 0.95; line-height: 1.7; }
.label { color: #6b859f; font-size: 24rpx; }
.value { margin-top: 8rpx; font-size: 28rpx; color: #213a55; }
.value.strong { font-size: 32rpx; font-weight: 700; }
.meta { margin-top: 8rpx; color: #476887; font-size: 24rpx; }
.score-track { height: 10rpx; background: #edf5fb; border-radius: 999rpx; overflow: hidden; margin-top: 14rpx; }
.score-fill { height: 100%; background: linear-gradient(90deg, #79d6ff 0%, #00aaff 100%); border-radius: inherit; }
.detail { margin-top: 10rpx; color: #2f4964; line-height: 1.8; font-size: 25rpx; }
.actions { display: flex; gap: 12rpx; }
.btn { flex: 1; background: #00aaff; color: #fff; border-radius: 12rpx; font-size: 28rpx; }
.btn.ghost { background: #eef8ff; color: #00aaff; border: 1px solid #00aaff; }
.empty-card { border: 1px dashed #c9dfef; background: #f9fcff; }
.empty-title { color: #1e456c; font-size: 30rpx; font-weight: 700; }
.empty-desc { margin: 10rpx 0 14rpx; color: #7390a9; font-size: 24rpx; }
</style>
