<template>
  <view class="page">
    <view class="card hero" v-if="isFirstEntry">
      <view class="hero-title">欢迎首次使用航班餐食预选</view>
      <view class="hero-desc">请先完善饮食偏好画像，系统将生成更准确的个性化推荐。</view>
      <view class="hero-pill">画像初始化</view>
    </view>

    <view class="card" v-else>
      <view class="section-head">
        <view class="title">偏好画像中心</view>
        <view class="status-badge">{{ likedFlavors.length }} 个口味标签</view>
      </view>
      <view class="tip">偏好越完整，推荐越稳定；后续可在“我的”页随时修改。</view>
    </view>

    <view class="card">
      <view class="title">喜欢的口味（可多选）</view>
      <view class="tag-wrap">
        <view
          class="tag"
          :class="{ active: likedFlavors.includes(tag) }"
          v-for="tag in flavorOptions"
          :key="tag"
          @click="toggleLikedFlavor(tag)"
        >
          {{ tag }}
        </view>
      </view>
    </view>

    <view class="card">
      <view class="title">偏好餐型</view>
      <picker mode="selector" :range="mealTypeOptions" range-key="label" @change="onMealTypeChange">
        <view class="picker">{{ selectedMealTypeLabel }}</view>
      </picker>
      <view class="title small">补充说明</view>
      <input v-model="dietaryNotes" placeholder="如：少油、不要香菜、偏热食" maxlength="60" />
      <view class="tip note">说明将用于推荐解释与后厨备餐备注。</view>
      <button type="button" class="submit" :disabled="submitting" @click="save">{{ submitting ? '保存中...' : '保存偏好并进入推荐' }}</button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import { getPreferenceAPI, savePreferenceAPI } from '@/api/preference'
import type { UserPreference } from '@/types/aviation'

const isFirstEntry = ref(false)
const flavorOptions = ['清淡', '咸香', '微辣', '甜口', '低脂', '高蛋白']
const mealTypeOptions = [
  { value: '1', label: '儿童餐' },
  { value: '2', label: '标准餐' },
  { value: '3', label: '清真餐' },
  { value: '4', label: '素食餐' },
]

const likedFlavors = ref<string[]>([])
const mealType = ref('2')
const dietaryNotes = ref('')
const submitting = ref(false)

const selectedMealTypeLabel = computed(() => {
  return mealTypeOptions.find((item) => item.value === mealType.value)?.label || '请选择餐型'
})

const parseJsonArray = (raw?: string) => {
  if (!raw) return [] as string[]
  try {
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return raw ? [raw] : []
  }
}

const onMealTypeChange = (event: any) => {
  const index = Number(event.detail.value)
  mealType.value = mealTypeOptions[index].value
}

const toggleLikedFlavor = (tag: string) => {
  if (likedFlavors.value.includes(tag)) {
    likedFlavors.value = likedFlavors.value.filter((item) => item !== tag)
    return
  }
  likedFlavors.value = [...likedFlavors.value, tag]
}

const loadData = async () => {
  const res = await getPreferenceAPI()
  if (!res.data) return
  likedFlavors.value = parseJsonArray(res.data.flavorPreferences)
  const mealTypeList = parseJsonArray(res.data.mealTypePreferences)
  mealType.value = mealTypeList[0] || '2'
  dietaryNotes.value = res.data.dietaryNotes || ''
}

const save = async () => {
  if (submitting.value) {
    return
  }
  if (!likedFlavors.value.length) {
    uni.showToast({ title: '请至少选择一个喜欢口味', icon: 'none' })
    return
  }
  const payload: UserPreference = {
    mealTypePreferences: JSON.stringify([mealType.value]),
    flavorPreferences: JSON.stringify(likedFlavors.value),
    dietaryNotes: dietaryNotes.value,
  }
  submitting.value = true
  try {
    await savePreferenceAPI(payload)
    uni.showToast({ title: '偏好已保存', icon: 'none' })
    setTimeout(() => {
      uni.redirectTo({ url: '/pages/recommendation/recommendation' })
    }, 300)
  } finally {
    submitting.value = false
  }
}

onLoad((options) => {
  isFirstEntry.value = options?.first === '1'
})

onShow(() => {
  void loadData()
})
</script>

<style scoped>
.page { padding: 24rpx; background: linear-gradient(180deg, #eef8ff 0%, #f7fbff 100%); min-height: 100vh; }
.card { background: #fff; border-radius: 20rpx; padding: 24rpx; margin-bottom: 20rpx; box-shadow: 0 8rpx 20rpx rgba(34, 170, 238, 0.08); }
.hero { background: linear-gradient(135deg, #00aaff 0%, #59c7ff 100%); color: #fff; }
.hero-title { font-size: 32rpx; font-weight: 700; margin-bottom: 8rpx; }
.hero-desc { font-size: 24rpx; opacity: 0.95; line-height: 1.7; }
.hero-pill { margin-top: 14rpx; display: inline-block; padding: 6rpx 16rpx; border-radius: 999rpx; font-size: 22rpx; background: rgba(255, 255, 255, 0.22); border: 1rpx solid rgba(255, 255, 255, 0.38); }
.title { font-size: 30rpx; font-weight: 700; color: #114477; margin-bottom: 16rpx; }
.title.small { margin-top: 18rpx; }
.section-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8rpx; }
.status-badge { padding: 6rpx 14rpx; border-radius: 999rpx; background: #eaf6ff; color: #00aaff; font-size: 22rpx; }
.tip { color: #6a7c92; font-size: 24rpx; line-height: 1.7; }
.tip.note { margin-top: 10rpx; }
.tag-wrap { display: flex; flex-wrap: wrap; gap: 12rpx; }
.tag { padding: 10rpx 20rpx; border-radius: 28rpx; border: 1px solid #99dfff; color: #1188cc; background: #f3fbff; font-size: 24rpx; }
.tag.active { background: #00aaff; border-color: #00aaff; color: #fff; }
.picker { border: 1px solid #dbe8f5; border-radius: 12rpx; padding: 16rpx; color: #333; }
input { border: 1px solid #dbe8f5; border-radius: 12rpx; padding: 16rpx; margin-top: 10rpx; }
.submit { margin-top: 24rpx; background: #00aaff; color: #fff; border-radius: 12rpx; }
</style>
