<template>
  <view class="page">
    <view class="aurora aurora-a"></view>
    <view class="aurora aurora-b"></view>

    <view class="hero card">
      <view class="hero-top">
        <view>
          <view class="hero-kicker">AERO CULINARY ATLAS</view>
          <view class="hero-title">云端餐食预选</view>
          <view class="hero-desc">按你的航线与偏好，生成本次航程专属菜单。</view>
        </view>
        <view class="hero-dot"></view>
      </view>
      <view class="hero-metrics">
        <view class="metric">
          <view class="metric-value">{{ candidateFlights.length }}</view>
          <view class="metric-label">可切换航班</view>
        </view>
        <view class="metric">
          <view class="metric-value">{{ list.length }}</view>
          <view class="metric-label">推荐菜品</view>
        </view>
      </view>
    </view>

    <view class="rating-card card" v-if="pendingRatingList.length">
      <view>
        <view class="rating-title">航班已结束，待评分 {{ pendingRatingList.length }} 条</view>
        <view class="rating-desc">你的评分会直接影响下一次推荐排序。</view>
      </view>
      <button class="rating-btn" @click="openRatingPage">去评分</button>
    </view>

    <view class="card" v-if="candidateFlights.length">
      <view class="section-head">
        <view class="title">当前航班</view>
        <view class="chip">{{ candidateFlights.length }} 个可选</view>
      </view>
      <picker mode="selector" :range="candidateFlights" range-key="flightNumber" @change="onFlightChange" :value="selectedFlightIndex">
        <view class="picker">{{ currentFlight ? `${currentFlight.flightNumber} · ${currentFlight.departure} -> ${currentFlight.destination}` : '请选择航班' }}</view>
      </picker>
      <view class="deadline" v-if="currentFlight?.selectionDeadline">预选截止：{{ formatDeadline(currentFlight.selectionDeadline) }}</view>
    </view>

    <view class="card state-card" v-if="currentFlight">
      <view class="section-head">
        <view class="title">预选状态</view>
        <view class="chip" :class="selectionPhase === 'selected' ? 'state-ok' : 'state-warn'">{{ selectionPhaseText }}</view>
      </view>
      <view class="state-main">当前餐次：{{ selectedMealOrderLabel }}</view>
      <view class="state-main">{{ selectionMainText }}</view>
      <view class="state-sub">{{ selectionSubText }}</view>
      <view class="state-tags">
        <view class="state-tag">{{ currentFlight.flightNumber }} {{ selectedMealOrderLabel }}：{{ hasManualSelectionForCurrentFlight ? '已选' : '未选' }}</view>
        <view class="state-tag">截止：{{ formatDeadline(currentFlight.selectionDeadline) }}</view>
      </view>
      <view class="selected-dish" v-if="selectionPhase === 'selected'">
        <view class="selected-kicker">当前已选</view>
        <view class="selected-name">{{ selectedDishName }}</view>
      </view>
    </view>

    <view class="card">
      <view class="section-head">
        <view class="title">筛选偏好</view>
        <view class="chip ghost">{{ selectedMealTypeLabel }}</view>
      </view>
      <view class="label">口味</view>
      <view class="tag-wrap">
        <view class="tag" :class="{ active: selectedFlavor === '' }" @click="selectedFlavor = ''">全部</view>
        <view class="tag" :class="{ active: selectedFlavor === item }" v-for="item in flavorOptions" :key="item" @click="selectedFlavor = item">{{ item }}</view>
      </view>
      <view class="label">餐型</view>
      <picker mode="selector" :range="mealTypeOptions" range-key="label" @change="onMealTypeChange">
        <view class="picker">{{ selectedMealTypeLabel }}</view>
      </picker>
      <view class="label" v-if="mealOrderOptions.length > 1">预选餐次</view>
      <picker v-if="mealOrderOptions.length > 1" mode="selector" :range="mealOrderOptions" range-key="label" :value="selectedMealOrderIndex" @change="onMealOrderChange">
        <view class="picker">{{ selectedMealOrderLabel }}</view>
      </picker>
      <view class="action-row">
        <button class="btn ghost" @click="resetFilter">重置</button>
        <button class="btn" :disabled="loading" @click="loadData">{{ loading ? '同步中...' : '刷新推荐' }}</button>
      </view>
    </view>

    <view class="card empty-card" v-if="!loading && list.length === 0">
      <view class="empty-title">暂无匹配餐食</view>
      <view class="empty-desc">调整口味或餐型后刷新，系统会自动重排候选。</view>
    </view>

    <view v-if="list.length" class="dish-window">
      <swiper
        class="dish-swiper"
        :current="swiperCurrent"
        :circular="list.length > 1"
        :duration="280"
        previous-margin="16rpx"
        next-margin="16rpx"
        @change="onSwiperChange"
      >
        <swiper-item v-for="(item, index) in list" :key="`${item.dishId}-${index}`">
          <view class="dish-card">
            <view class="dish-media">
              <image class="dish-image" :src="resolveDishImage(item, index)" mode="aspectFill"></image>
              <view class="media-fade"></view>
              <view class="media-badge">{{ isDishCurrentSelected(item) ? '当前已选' : '本次优选' }}</view>
            </view>
            <view class="dish-main">
              <view class="dish-head">
                <view class="dish-title">{{ item.dishName }}</view>
                <view class="score-pill">{{ Math.round((item.score || 0) * 100) }}%</view>
              </view>
              <view class="score-track">
                <view class="score-fill" :style="{ width: `${Math.round((item.score || 0) * 100)}%` }"></view>
              </view>
              <view class="dish-detail">{{ item.detail || '营养均衡，适合航旅场景。' }}</view>
              <view class="meta-row">
                <view class="meta-tag">{{ formatMealType(item.mealType) }}</view>
                <view class="meta-tag">{{ formatFlavor(item.flavorTags) }}</view>
                <view class="meta-tag">候选 {{ index + 1 }}</view>
              </view>
              <view class="dish-meta">推荐依据：{{ item.explainReason || '基础营养均衡推荐' }}</view>
              <view
                class="choose-btn"
                :class="{ disabled: isSelectionClosed || isDishCurrentSelected(item), selected: isDishCurrentSelected(item) }"
                :hover-class="isSelectionClosed || isDishCurrentSelected(item) ? 'none' : 'choose-btn-hover'"
                @click="goSelect(item)"
              >
                {{ selectionActionText(item) }}
              </view>
            </view>
          </view>
        </swiper-item>
      </swiper>
      <view class="swiper-indicator">
        <view class="dot" :class="{ active: swiperCurrent === index }" v-for="(_, index) in list" :key="index"></view>
      </view>
    </view>

    <view class="card" v-if="ranking.length">
      <view class="section-head">
        <view class="title">热门榜单</view>
        <view class="chip">TOP {{ ranking.length }}</view>
      </view>
      <view class="rank-item" v-for="(item, index) in ranking" :key="item.dishId">
        <view class="rank-left">
          <view class="rank-index">{{ index + 1 }}</view>
          <view class="rank-name">{{ item.dishName }}</view>
        </view>
        <view class="rank-count">{{ item.selectCount }} 次</view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import {
  getPendingRatingAPI,
  getRecommendationHistoryAPI,
  getRecommendationListAPI,
  getRecommendationTopAPI,
} from '@/api/recommendation'
import { bindFlightAPI } from '@/api/flight'
import { useFlightContext } from '@/composables/useFlightContext'
import type { FlightInfo, PendingRatingInfo, RecommendationDish, RecommendationTopItem, RecommendConfirmPayload } from '@/types/aviation'

const flavorOptions = ['清淡', '咸香', '微辣', '甜口', '低脂', '高蛋白']
const mealTypeOptions = [
  {value: '', label: '全部餐型'},
  {value: '1', label: '儿童餐'},
  {value: '2', label: '标准餐'},
  {value: '3', label: '清真餐'},
  {value: '4', label: '素食餐'},
]

const selectedFlavor = ref('')
const selectedMealType = ref('')
const selectedMealOrder = ref(1)
const list = ref<RecommendationDish[]>([])
const ranking = ref<RecommendationTopItem[]>([])
const recommendationHistory = ref<Record<string, unknown>[]>([])
const pendingRatingList = ref<PendingRatingInfo[]>([])
const selectedMealTypeLabel = ref('全部餐型')
const candidateFlights = ref<FlightInfo[]>([])
const currentFlight = ref<FlightInfo | null>(null)
const selectedFlightIndex = ref(0)
const swiperCurrent = ref(0)
const loading = ref(false)
const {loadFlightContext: loadFlightContextData} = useFlightContext()
const fallbackDishImages = ['/static/images/swp1.png', '/static/images/swp2.png', '/static/images/swp3.png']

const resolveDishImage = (item: RecommendationDish, index: number) => {
  const pic = item?.pic ? String(item.pic).trim() : ''
  if (pic) return pic
  return fallbackDishImages[index % fallbackDishImages.length]
}

const onSwiperChange = (event: any) => {
  swiperCurrent.value = Number(event.detail.current || 0)
}

const onMealTypeChange = (event: any) => {
  const index = Number(event.detail.value)
  const option = mealTypeOptions[index]
  selectedMealType.value = option.value
  selectedMealTypeLabel.value = option.label
}

const mealOrderOptions = computed(() => {
  const count = Math.max(1, Math.min(Number(currentFlight.value?.mealCount || 1), 3))
  return Array.from({ length: count }, (_, idx) => ({ value: idx + 1, label: `第${idx + 1}餐` }))
})

const selectedMealOrderIndex = computed(() => {
  const idx = mealOrderOptions.value.findIndex((item) => item.value === selectedMealOrder.value)
  return idx >= 0 ? idx : 0
})

const selectedMealOrderLabel = computed(() => {
  const matched = mealOrderOptions.value.find((item) => item.value === selectedMealOrder.value)
  return matched?.label || '第1餐'
})

const onMealOrderChange = (event: any) => {
  const index = Number(event.detail.value)
  const option = mealOrderOptions.value[index]
  if (!option) return
  selectedMealOrder.value = option.value
  void loadRecommendationData()
}

const resetFilter = () => {
  selectedFlavor.value = ''
  selectedMealType.value = ''
  selectedMealTypeLabel.value = '全部餐型'
  selectedMealOrder.value = 1
  void loadData()
}

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
    if (!feedback.startsWith('MANUAL_SELECTED')) return false
    const orderMatch = feedback.match(/mealOrder=(\d+)/)
    const order = orderMatch?.[1] ? Number(orderMatch[1]) : 1
    return order === selectedMealOrder.value
  })
})

const latestManualSelection = computed(() => {
  const flightId = currentFlight.value?.id
  if (!flightId) return null

  const rows = recommendationHistory.value.filter((item) => {
    const row = item as Record<string, unknown>
    const rowFlightIdRaw = row.flightId ?? row.flight_id
    const rowFlightId = Number(rowFlightIdRaw)
    if (Number.isNaN(rowFlightId) || rowFlightId !== flightId) return false
    const feedback = String(row.userFeedback ?? row.user_feedback ?? '')
    if (!feedback.startsWith('MANUAL_SELECTED')) return false
    const orderMatch = feedback.match(/mealOrder=(\d+)/)
    const order = orderMatch?.[1] ? Number(orderMatch[1]) : 1
    return order === selectedMealOrder.value
  }) as Array<Record<string, unknown>>

  if (!rows.length) return null
  return [...rows].sort((a, b) => Number(b.id ?? 0) - Number(a.id ?? 0))[0]
})

const extractDishIdFromText = (value: unknown) => {
  if (value == null) return undefined
  const text = String(value)
  const matched = text.match(/dishId=(\d+)|(\d+)/)
  const numText = matched?.[1] || matched?.[2]
  if (!numText) return undefined
  const num = Number(numText)
  return Number.isNaN(num) ? undefined : num
}

const selectedDishId = computed(() => {
  if (!latestManualSelection.value) return undefined
  const fromFeedback = extractDishIdFromText(latestManualSelection.value.userFeedback ?? latestManualSelection.value.user_feedback)
  if (fromFeedback) return fromFeedback
  return extractDishIdFromText(latestManualSelection.value.recommendedDishes ?? latestManualSelection.value.recommended_dishes)
})

const selectedDishName = computed(() => {
  if (!selectedDishId.value) return '已确认餐食'
  const matched = list.value.find((item) => item.dishId === selectedDishId.value)
  if (matched?.dishName) return matched.dishName
  return `餐食 #${selectedDishId.value}`
})

const selectionPhase = computed<'selected' | 'unselected'>(() => {
  return hasManualSelectionForCurrentFlight.value ? 'selected' : 'unselected'
})

const selectionPhaseText = computed(() => {
  return selectionPhase.value === 'selected' ? '已预选餐食' : '未预选餐食'
})

const selectionMainText = computed(() => {
  if (selectionPhase.value === 'selected') {
    return '你已完成本航班预选，可按需改选。'
  }
  return '你尚未完成本航班预选，请尽快确认餐食。'
})

const selectionSubText = computed(() => {
  if (isSelectionClosed.value) {
    return hasManualSelectionForCurrentFlight.value ? '当前航班已截止，已选餐食等待系统配餐。' : '当前航班已截止，系统将自动进行餐食分配。'
  }
  return selectionPhase.value === 'selected'
    ? '截止前可继续调整，最后一次确认将作为最终预选。'
    : '截止前可自由选择并确认，推荐会根据偏好实时更新。'
})

const isDishCurrentSelected = (item: RecommendationDish) => {
  return !!selectedDishId.value && item?.dishId === selectedDishId.value
}

const selectionActionText = (item: RecommendationDish) => {
  if (isSelectionClosed.value) {
    return hasManualSelectionForCurrentFlight.value ? '该航班已完成预选' : '该航班已截止'
  }
  if (isDishCurrentSelected(item)) {
    return '当前已选'
  }
  return selectionPhase.value === 'selected' ? '改选并确认' : '选择并确认'
}

const onFlightChange = async (event: any) => {
  const index = Number(event.detail.value)
  selectedFlightIndex.value = index
  const target = candidateFlights.value[index]
  if (!target?.id) return
  await bindFlightAPI(target.id)
  currentFlight.value = target
  uni.showToast({title: '已切换航班', icon: 'none'})
  await loadRecommendationData()
}

const loadFlightContext = async () => {
  const context = await loadFlightContextData()
  if (!context.ok) {
    uni.showToast({title: '请先在航班页完成身份初始化', icon: 'none'})
    uni.switchTab({url: '/pages/flight/flight'})
    return false
  }
  currentFlight.value = context.currentFlight
  candidateFlights.value = context.candidateFlights
  if (currentFlight.value && candidateFlights.value.length > 0) {
    const currentFlightId = currentFlight.value.id
    const idx = candidateFlights.value.findIndex((item) => item.id === currentFlightId)
    selectedFlightIndex.value = idx >= 0 ? idx : 0
  }
  const mealCount = Math.max(1, Math.min(Number(currentFlight.value?.mealCount || 1), 3))
  if (selectedMealOrder.value > mealCount) {
    selectedMealOrder.value = 1
  }
  return !!currentFlight.value
}

const loadRecommendationData = async () => {
  const currentDishId = list.value[swiperCurrent.value]?.dishId
  const [recRes, rankRes, historyRes, pendingRes] = await Promise.all([
    getRecommendationListAPI({
      flavor: selectedFlavor.value || undefined,
      mealType: selectedMealType.value ? Number(selectedMealType.value) : undefined,
      mealOrder: selectedMealOrder.value,
      size: 10,
    }),
    getRecommendationTopAPI(5),
    getRecommendationHistoryAPI(),
    getPendingRatingAPI(),
  ])
  list.value = recRes.data || []
  ranking.value = rankRes.data || []
  recommendationHistory.value = historyRes.data || []
  pendingRatingList.value = pendingRes.data || []

  // Keep current slide aligned with refreshed data while preserving swiper instance,
  // which avoids intermittent gesture interruption on mini-app clients.
  let nextIndex = 0
  if (currentDishId != null) {
    const matchedIndex = list.value.findIndex((item) => item.dishId === currentDishId)
    if (matchedIndex >= 0) {
      nextIndex = matchedIndex
    }
  }
  if (nextIndex >= list.value.length) {
    nextIndex = Math.max(0, list.value.length - 1)
  }
  swiperCurrent.value = nextIndex
}

const loadData = async () => {
  loading.value = true
  try {
    const ok = await loadFlightContext()
    if (!ok) {
      list.value = []
      ranking.value = []
      recommendationHistory.value = []
      pendingRatingList.value = []
      return
    }
    await loadRecommendationData()
  } finally {
    loading.value = false
  }
}

const openRatingPage = () => {
  if (!pendingRatingList.value.length) return
  uni.switchTab({url: '/pages/flightRating/flightRating'})
}

const goSelect = (item: RecommendationDish) => {
  if (isSelectionClosed.value) {
    const title = hasManualSelectionForCurrentFlight.value
      ? '该航班预选已截止，等待系统配餐'
      : '该航班预选已截止，系统将自动配餐'
    uni.showToast({title, icon: 'none'})
    return
  }
  if (!item?.dishId) {
    uni.showToast({title: '餐食数据异常', icon: 'none'})
    return
  }
  const payloadData: RecommendConfirmPayload = {
    dishId: item.dishId,
    mealOrder: selectedMealOrder.value,
    mealOrderLabel: selectedMealOrderLabel.value,
    dishName: item.dishName,
    detail: item.detail,
    mealType: item.mealType,
    flavorTags: item.flavorTags,
    score: item.score,
    explainReason: item.explainReason,
    fallbackLevel: item.fallbackLevel ?? 0,
    flightNumber: currentFlight.value?.flightNumber,
    departure: currentFlight.value?.departure,
    destination: currentFlight.value?.destination,
    selectionDeadline: currentFlight.value?.selectionDeadline,
  }
  const payload = encodeURIComponent(JSON.stringify(payloadData))
  uni.navigateTo({url: `/pages/recommendConfirm/recommendConfirm?payload=${payload}`})
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
  --ink-2: #486681;
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

.aurora {
  position: absolute;
  z-index: 0;
  border-radius: 999rpx;
  filter: blur(16rpx);
  opacity: 0.5;
}

.aurora-a {
  width: 300rpx;
  height: 300rpx;
  right: -90rpx;
  top: 120rpx;
  background: #7dd5ff;
}

.aurora-b {
  width: 260rpx;
  height: 260rpx;
  left: -80rpx;
  bottom: 180rpx;
  background: #ffcf90;
}

.card,
.dish-card {
  position: relative;
  z-index: 2;
  border-radius: 30rpx;
  padding: 24rpx;
  margin-bottom: 18rpx;
  border: 1px solid var(--line);
  background: rgba(255, 255, 255, 0.95);
  box-shadow: 0 20rpx 42rpx rgba(17, 56, 94, 0.1);
  backdrop-filter: blur(8rpx);
  animation: rise-in 380ms ease both;
}

.hero {
  background: linear-gradient(138deg, #0b76c2 0%, #1299d1 52%, #35b5dd 100%);
  color: #fff;
  border-color: rgba(255, 255, 255, 0.3);
}

.hero-kicker {
  font-size: 20rpx;
  letter-spacing: 2rpx;
  opacity: 0.9;
  margin-bottom: 6rpx;
}

.hero-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.hero-title {
  font-size: 42rpx;
  font-weight: 800;
  letter-spacing: 1rpx;
}

.hero-desc {
  margin-top: 8rpx;
  opacity: 0.95;
  line-height: 1.8;
  font-size: 24rpx;
}

.hero-dot {
  width: 26rpx;
  height: 26rpx;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.8);
  margin-top: 8rpx;
}

.hero-metrics {
  margin-top: 22rpx;
  display: flex;
  gap: 12rpx;
}

.metric {
  flex: 1;
  border-radius: 16rpx;
  background: rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.34);
  padding: 12rpx;
}

.metric-value {
  font-size: 32rpx;
  font-weight: 800;
}

.metric-label {
  margin-top: 4rpx;
  font-size: 22rpx;
}

.rating-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(130deg, #fff3dc 0%, #fff 44%, #ecf8ff 100%);
}

.rating-title {
  color: #1f3955;
  font-size: 30rpx;
  font-weight: 700;
}

.rating-desc {
  margin-top: 8rpx;
  color: #667f9a;
  font-size: 24rpx;
}

.rating-btn {
  width: 150rpx;
  height: 72rpx;
  line-height: 72rpx;
  border-radius: 36rpx;
  background: linear-gradient(135deg, #ffab31 0%, #f58323 100%);
  color: #fff;
  font-size: 26rpx;
}

.section-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10rpx;
}

.title {
  font-size: 32rpx;
  font-weight: 800;
  color: var(--ink-1);
}

.chip {
  padding: 8rpx 16rpx;
  border-radius: 999rpx;
  background: #e8f6ff;
  color: var(--brand-1);
  font-size: 22rpx;
}

.chip.ghost {
  background: #f4f8fc;
  color: #68829c;
}

.chip.state-ok {
  background: #e9f8f0;
  color: #2f8f63;
}

.chip.state-warn {
  background: #fff4e2;
  color: #b7751c;
}

.state-card {
  background: linear-gradient(135deg, #fefefe 0%, #f4fbff 100%);
}

.state-main {
  margin-top: 6rpx;
  font-size: 28rpx;
  color: #1c3b57;
  font-weight: 700;
}

.state-sub {
  margin-top: 8rpx;
  font-size: 23rpx;
  color: #65819a;
  line-height: 1.7;
}

.state-tags {
  margin-top: 12rpx;
  display: flex;
  flex-wrap: wrap;
  gap: 10rpx;
}

.state-tag {
  padding: 7rpx 14rpx;
  border-radius: 999rpx;
  border: 1px solid #d7e8f6;
  background: #f6fbff;
  color: #3f6788;
  font-size: 22rpx;
}

.selected-dish {
  margin-top: 14rpx;
  border-radius: 16rpx;
  padding: 14rpx 16rpx;
  background: linear-gradient(135deg, #edf8ff 0%, #fff3e2 100%);
  border: 1px solid #d9ebfa;
}

.selected-kicker {
  font-size: 21rpx;
  color: #5f7c95;
}

.selected-name {
  margin-top: 6rpx;
  font-size: 28rpx;
  color: #1f4567;
  font-weight: 700;
}

.label {
  color: #5e7791;
  font-size: 25rpx;
  margin: 10rpx 0;
}

.tag-wrap {
  display: flex;
  flex-wrap: wrap;
  gap: 10rpx;
  margin-bottom: 8rpx;
}

.tag {
  padding: 10rpx 18rpx;
  border-radius: 999rpx;
  border: 1px solid #c7ddf3;
  color: #2f608e;
  background: #f8fbff;
  font-size: 24rpx;
}

.tag.active {
  background: linear-gradient(135deg, var(--brand-1) 0%, var(--brand-2) 100%);
  border-color: transparent;
  color: #fff;
}

.picker {
  border: 1px solid #d5e5f5;
  border-radius: 14rpx;
  padding: 16rpx;
  color: #294865;
  font-size: 26rpx;
  background: #fbfdff;
}

.deadline {
  margin-top: 10rpx;
  font-size: 23rpx;
  color: #68829a;
}

.action-row {
  display: flex;
  gap: 12rpx;
  margin-top: 16rpx;
}

.btn {
  flex: 1;
  border-radius: 14rpx;
  background: linear-gradient(135deg, var(--brand-1) 0%, var(--brand-2) 100%);
  color: #fff;
  font-size: 26rpx;
}

.btn.ghost {
  background: #f3f7fb;
  color: #4e6883;
  border: 1px solid #d9e4ef;
}

.empty-card {
  border-style: dashed;
}

.empty-title {
  color: #1f3d58;
  font-size: 30rpx;
  font-weight: 700;
}

.empty-desc {
  margin-top: 8rpx;
  color: #7891a8;
  font-size: 24rpx;
}

.dish-window {
  position: relative;
  z-index: 2;
  margin-bottom: 18rpx;
}

.dish-swiper {
  height: 760rpx;
}

.dish-card {
  margin: 0 8rpx;
  padding: 0;
  overflow: hidden;
  border-radius: 26rpx;
  border: 1px solid #e6eef8;
  background: rgba(255, 255, 255, 0.92);
  box-shadow: 0 14rpx 34rpx rgba(19, 54, 94, 0.08);
}

.dish-media {
  height: 320rpx;
  position: relative;
  overflow: hidden;
  border-bottom: 1px solid #e7f0f8;
  border-top-left-radius: 26rpx;
  border-top-right-radius: 26rpx;
  background: linear-gradient(160deg, #f0f7ff 0%, #e8f3ff 100%);
}

.dish-image {
  width: 100%;
  height: 100%;
  display: block;
  object-fit: cover;
  object-position: center;
}

.media-fade {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 92rpx;
  background: linear-gradient(180deg, rgba(0, 0, 0, 0) 0%, rgba(8, 32, 54, 0.55) 100%);
}

.media-badge {
  position: absolute;
  left: 16rpx;
  bottom: 14rpx;
  padding: 6rpx 14rpx;
  border-radius: 999rpx;
  background: rgba(255, 255, 255, 0.9);
  color: #214f76;
  font-size: 21rpx;
  font-weight: 700;
}

.dish-main {
  padding: 24rpx;
  background: linear-gradient(145deg, #ffffff 0%, #f6fbff 100%);
}

.dish-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.dish-title {
  font-size: 33rpx;
  font-weight: 800;
  color: #15334f;
}

.score-pill {
  padding: 6rpx 14rpx;
  border-radius: 999rpx;
  color: #0c89cc;
  background: #eaf8ff;
  font-size: 22rpx;
}

.score-track {
  margin-top: 12rpx;
  height: 10rpx;
  background: #e8f0f8;
  border-radius: 999rpx;
  overflow: hidden;
}

.score-fill {
  height: 100%;
  background: linear-gradient(90deg, #6dd8ff 0%, #13a7e2 100%);
}

.dish-detail {
  margin-top: 10rpx;
  color: #3e5e7c;
  font-size: 24rpx;
  line-height: 1.75;
}

.meta-row {
  margin-top: 12rpx;
  display: flex;
  gap: 8rpx;
  flex-wrap: wrap;
}

.meta-tag {
  padding: 6rpx 12rpx;
  border-radius: 999rpx;
  background: #f0f7ff;
  border: 1px solid #d1e6f7;
  color: #2b618f;
  font-size: 22rpx;
}

.dish-meta {
  margin-top: 8rpx;
  color: #6a8197;
  font-size: 23rpx;
}

.choose-btn {
  margin-top: 16rpx;
  border-radius: 16rpx;
  background: linear-gradient(135deg, var(--brand-1) 0%, var(--brand-2) 100%);
  color: #fff;
  font-size: 26rpx;
}

.choose-btn.disabled {
  background: #d8e3ee;
  color: #6f8598;
}

.choose-btn.selected {
  background: #eef4fa;
  color: #68839d;
}

.choose-btn-hover {
  opacity: 0.92;
}

.swiper-indicator {
  margin-top: 12rpx;
  display: flex;
  justify-content: center;
  gap: 10rpx;
}

.dot {
  width: 12rpx;
  height: 12rpx;
  border-radius: 50%;
  background: #c9d9e9;
}

.dot.active {
  width: 34rpx;
  border-radius: 10rpx;
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

.rank-item {
  padding: 12rpx 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #eef3f8;
}

.rank-item:last-child {
  border-bottom: none;
}

.rank-left {
  display: flex;
  align-items: center;
  gap: 10rpx;
}

.rank-index {
  width: 34rpx;
  height: 34rpx;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 22rpx;
  background: linear-gradient(135deg, var(--brand-1) 0%, var(--brand-2) 100%);
}

.rank-name {
  color: #21405c;
  font-size: 26rpx;
}

.rank-count {
  color: #4f6f8d;
  font-size: 24rpx;
}
</style>
