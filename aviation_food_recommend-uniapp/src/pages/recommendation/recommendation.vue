<template>
  <view class="page">
    <view class="aurora aurora-a"></view>
    <view class="aurora aurora-b"></view>

    <!-- ====== ① Hero + Flight Status ====== -->
    <view class="hero card">
      <view class="hero-top">
        <view>
          <view class="hero-kicker">AERO CULINARY ATLAS</view>
          <view class="hero-title">云端餐食预选</view>
        </view>
        <view class="hero-badge" v-if="currentFlight">{{ selectedMealOrderLabel }}</view>
      </view>
      <view class="hero-metrics">
        <view class="metric"><view class="metric-value">{{ candidateFlights.length }}</view><view class="metric-label">可选航班</view></view>
        <view class="metric"><view class="metric-value">{{ list.length }}</view><view class="metric-label">推荐菜品</view></view>
        <view class="metric"><view class="metric-value">{{ currentFlightSelectionProgress.completedCount }}/{{ currentFlightSelectionProgress.totalMealCount }}</view><view class="metric-label">预选进度</view></view>
      </view>
    </view>

    <!-- Rating prompt -->
    <view class="rating-card card" v-if="pendingRatingList.length">
      <view><view class="rating-title">待评分 {{ pendingRatingList.length }} 条</view><view class="rating-desc">评分会直接影响推荐排序</view></view>
      <button class="rating-btn" @click="openRatingPage">去评分</button>
    </view>

    <!-- Flight picker -->
    <view class="card" v-if="candidateFlights.length">
      <picker mode="selector" :range="candidateFlights" range-key="flightNumber" @change="onFlightChange" :value="selectedFlightIndex">
        <view class="flight-picker">
          <view class="flight-picker-left">
            <view class="flight-no">{{ currentFlight?.flightNumber || '选择航班' }}</view>
            <view class="flight-route" v-if="currentFlight">{{ currentFlight.departure }} → {{ currentFlight.destination }}</view>
          </view>
          <view class="flight-picker-right">
            <view class="deadline" v-if="currentFlight?.selectionDeadline">截止 {{ formatDeadline(currentFlight.selectionDeadline) }}</view>
            <text class="arrow">›</text>
          </view>
        </view>
      </picker>
      <view class="status-bar" v-if="currentFlight">
        <view class="status-item" :class="{ done: hasManualSelectionForCurrentMeal }">{{ hasManualSelectionForCurrentMeal ? '✓' : '○' }} {{ selectedMealOrderLabel }}</view>
        <view class="status-item" :class="{ done: isSelectionClosed }">{{ isSelectionClosed ? '已截止' : '可预选' }}</view>
      </view>
    </view>

    <!-- Empty state -->
    <view class="card empty-card" v-if="!currentFlight && !candidateFlights.length && !loading">
      <view class="empty-title">暂无可预选航班</view>
      <view class="empty-desc">请在航班页核实身份信息并绑定航班。</view>
      <button class="btn ghost" style="margin-top:20rpx" @click="goToFlight">前往航班页</button>
    </view>

    <!-- ====== Meal Steps ====== -->
    <view class="meal-steps" v-if="currentFlight && mealOrderOptions.length > 1">
      <view v-for="opt in mealOrderOptions" :key="opt.value" class="meal-step"
        :class="{ current: selectedMealOrder === opt.value, done: isMealOrderDone(opt.value) }"
        @click="selectedMealOrder = opt.value; loadData()">
        <view class="step-dot"><text v-if="isMealOrderDone(opt.value)">✓</text><text v-else>{{ opt.value }}</text></view>
        <view class="step-label">{{ opt.label }}</view>
        <view class="step-line" v-if="opt.value < mealOrderOptions.length"></view>
      </view>
    </view>

    <!-- ====== ② TOP-3 ====== -->
    <view class="top3-section" v-if="list.length >= 3 && currentFlight">
      <view class="section-title"><text class="title-icon">🏆</text><text>金牌推荐 TOP-3</text></view>
      <view class="top3-grid">
        <view v-for="(item, idx) in list.slice(0, 3)" :key="'top3-'+item.dishId" class="top3-card"
          :class="['rank-'+(idx+1), { selected: isDishCurrentSelected(item) }]" @click="goSelect(item)">
          <view class="rank-badge" :class="'rank-'+(idx+1)"><text v-if="idx===0">👑</text><text v-else>{{ idx+1 }}</text></view>
          <view class="top3-media"><image class="top3-img" :src="resolveDishImage(item, idx)" mode="aspectFill"></image><view class="top3-fade"></view></view>
          <view class="top3-info">
            <view class="top3-name">{{ item.dishName }}</view>
            <view class="top3-tags"><text class="t3-tag">{{ formatFlavor(item.flavorTags) }}</text></view>
            <view class="top3-score-bar"><view class="top3-score-fill" :style="{width:(item.score||0)*100+'%'}"></view></view>
            <view class="top3-reason">{{ item.explainReason || '综合推荐' }}</view>
            <view class="top3-btn" :class="{active:isDishCurrentSelected(item)}">{{ isDishCurrentSelected(item) ? '已选择' : '选这个' }}</view>
          </view>
        </view>
      </view>
    </view>

    <!-- ====== ③ All Dishes Grid ====== -->
    <view class="all-section" v-if="list.length && currentFlight">
      <view class="section-title"><text class="title-icon">🍽️</text><text>全部餐食</text><view class="section-chip">{{ list.length }} 道可选</view></view>
      <scroll-view class="flavor-bar" scroll-x enable-flex :show-scrollbar="false">
        <view class="flavor-tag" :class="{active:selectedFlavor===''}" @click="selectedFlavor=''">全部口味</view>
        <view class="flavor-tag" :class="{active:selectedFlavor===f}" v-for="f in flavorOptions" :key="f" @click="selectedFlavor=f">{{ f }}</view>
      </scroll-view>
      <view class="dish-grid">
        <view v-for="(item, idx) in filteredList" :key="'grid-'+item.dishId" class="grid-card"
          :class="{selected:isDishCurrentSelected(item)}" @click="goSelect(item)">
          <view class="grid-media"><image class="grid-img" :src="resolveDishImage(item, idx)" mode="aspectFill"></image>
            <view v-if="isDishCurrentSelected(item)" class="grid-check">✓</view></view>
          <view class="grid-info"><view class="grid-name">{{ item.dishName }}</view>
            <view class="grid-tags"><text class="g-tag">{{ formatFlavor(item.flavorTags) }}</text></view></view>
        </view>
      </view>
      <view class="grid-empty" v-if="filteredList.length===0"><text>该口味暂无匹配餐食</text></view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { getPendingRatingAPI, getRecommendationHistoryAPI, getRecommendationListAPI, reportRecommendationClickAPI, getRecommendationTopAPI } from '@/api/recommendation'
import { bindFlightAPI } from '@/api/flight'
import { useFlightContext } from '@/composables/useFlightContext'
import { MEAL_TYPE_FILTER_OPTIONS, getMealTypeLabel } from '@/utils/meal'
import { findLatestManualSelectionForMealOrder, getFlightMealSelectionProgress, hasManualSelectionForMealOrder } from '@/utils/mealSelection'
import type { FlightInfo, PendingRatingInfo, RecommendationDish, RecommendationTopItem, RecommendConfirmPayload } from '@/types/aviation'

const flavorOptions = ['清淡','咸香','微辣','甜口','低脂','高蛋白']
const mealTypeOptions = MEAL_TYPE_FILTER_OPTIONS
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
const loading = ref(false)
const { loadFlightContext: loadFlightContextData } = useFlightContext()
const fallbackDishImages = ['/static/images/swp1.png','/static/images/swp2.png','/static/images/swp3.png']

const filteredList = computed(() => list.value.filter((item: any) => {
  if (selectedFlavor.value) { const tags = String(item.flavorTags || ''); if (!tags.includes(selectedFlavor.value)) return false }
  return true
}))

const resolveDishImage = (item: any, index: number) => {
  const pic = item?.pic ? String(item.pic).trim() : ''
  if (pic && pic.length < 200) { if (pic.startsWith('/dish-images/')) return imgBaseUrl + pic; return pic }
  const id = item?.dishId || index
  return fallbackDishImages[Math.abs(id * 7) % fallbackDishImages.length]
}
const imgBaseUrl = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8081').trim()

const mealOrderOptions = computed(() => {
  const count = Math.max(1, Math.min(Number(currentFlight.value?.mealCount || 1), 3))
  return Array.from({ length: count }, (_, idx) => ({ value: idx + 1, label: '第' + (idx + 1) + '餐' }))
})
const selectedMealOrderLabel = computed(() => {
  const matched = mealOrderOptions.value.find((item) => item.value === selectedMealOrder.value)
  return matched?.label || '第1餐'
})
const formatMealType = (value?: number) => getMealTypeLabel(value, '标准餐')
const formatFlavor = (value?: string) => { if (!value) return '清淡'; return String(value).replace(/[\[\]"]/g, '') }
const formatDeadline = (value?: string) => { if (!value) return '-'; return String(value).replace('T', ' ').slice(0, 16) }
const isSelectionClosed = computed(() => {
  const deadline = currentFlight.value?.selectionDeadline
  if (!deadline) return false
  return Date.now() > new Date(String(deadline).replace(' ', 'T')).getTime()
})
const currentFlightSelectionProgress = computed(() => getFlightMealSelectionProgress({
  history: recommendationHistory.value, flightId: currentFlight.value?.id, mealCount: currentFlight.value?.mealCount
}))
const hasManualSelectionForCurrentMeal = computed(() => hasManualSelectionForMealOrder({
  history: recommendationHistory.value, flightId: currentFlight.value?.id,
  mealCount: currentFlightSelectionProgress.value.totalMealCount, mealOrder: selectedMealOrder.value
}))
const latestManualSelection = computed(() => findLatestManualSelectionForMealOrder({
  history: recommendationHistory.value, flightId: currentFlight.value?.id,
  mealCount: currentFlightSelectionProgress.value.totalMealCount, mealOrder: selectedMealOrder.value
}))
const extractDishIdFromText = (value: unknown) => {
  if (value == null) return undefined
  const text = String(value)
  const matched = text.match(/dishId=(\d+)/)
  return matched ? Number(matched[1]) : undefined
}
const selectedDishId = computed(() => {
  if (!latestManualSelection.value) return undefined
  const fromFeedback = extractDishIdFromText(latestManualSelection.value.userFeedback ?? latestManualSelection.value.user_feedback)
  if (fromFeedback) return fromFeedback
  return extractDishIdFromText(latestManualSelection.value.recommendedDishes ?? latestManualSelection.value.recommended_dishes)
})
const isDishCurrentSelected = (item: RecommendationDish) => !!selectedDishId.value && item?.dishId === selectedDishId.value
const isMealOrderDone = (order: number) => hasManualSelectionForMealOrder({
  history: recommendationHistory.value, flightId: currentFlight.value?.id,
  mealCount: currentFlightSelectionProgress.value.totalMealCount, mealOrder: order
})

const onFlightChange = async (event: any) => {
  const index = Number(event.detail.value); selectedFlightIndex.value = index
  const target = candidateFlights.value[index]; if (!target?.id) return
  await bindFlightAPI(target.id); currentFlight.value = target
  uni.showToast({ title: '已切换航班', icon: 'none' }); await loadRecommendationData()
}
const loadFlightContext = async () => {
  const context = await loadFlightContextData()
  if (context.needIdentity) { uni.showToast({ title: '请先在航班页完成身份初始化', icon: 'none' }); uni.switchTab({ url: '/pages/flight/flight' }); return false }
  currentFlight.value = context.currentFlight; candidateFlights.value = context.candidateFlights
  if (currentFlight.value && candidateFlights.value.length > 0) {
    const idx = candidateFlights.value.findIndex((item) => item.id === currentFlight.value!.id)
    selectedFlightIndex.value = idx >= 0 ? idx : 0
  }
  const mealCount = Math.max(1, Math.min(Number(currentFlight.value?.mealCount || 1), 3))
  if (selectedMealOrder.value > mealCount) selectedMealOrder.value = 1
  return !!currentFlight.value
}
const loadRecommendationData = async () => {
  const [recRes, rankRes, historyRes, pendingRes] = await Promise.all([
    getRecommendationListAPI({ flavor: selectedFlavor.value || undefined, mealType: selectedMealType.value ? Number(selectedMealType.value) : undefined, mealOrder: selectedMealOrder.value, size: 10 }),
    getRecommendationTopAPI(5), getRecommendationHistoryAPI(), getPendingRatingAPI()
  ])
  list.value = recRes.data || []; ranking.value = rankRes.data || []
  recommendationHistory.value = historyRes.data || []; pendingRatingList.value = pendingRes.data || []
}
const loadData = async () => {
  loading.value = true
  try {
    const quickReload = uni.getStorageSync('quickReload') === '1'
    if (quickReload) uni.removeStorageSync('quickReload')
    if (!quickReload || !currentFlight.value) {
      const ok = await loadFlightContext()
      if (!ok) { list.value = []; ranking.value = []; recommendationHistory.value = []; pendingRatingList.value = []; return }
    }
    await loadRecommendationData()
  } catch { list.value = []; ranking.value = [] } finally { loading.value = false }
}
const goToFlight = () => uni.switchTab({ url: '/pages/flight/flight' })
const openRatingPage = () => { if (pendingRatingList.value.length) uni.switchTab({ url: '/pages/flightRating/flightRating' }) }
const reportRecommendationClick = (dishId: number, mealOrder: number) => { void reportRecommendationClickAPI(dishId, mealOrder).catch(() => {}) }
const goSelect = (item: RecommendationDish) => {
  if (isSelectionClosed.value) { uni.showToast({ title: '预选时间已截止', icon: 'none' }); return }
  if (!item?.dishId) { uni.showToast({ title: '餐食数据异常', icon: 'none' }); return }
  reportRecommendationClick(item.dishId, selectedMealOrder.value)
  const payloadData: RecommendConfirmPayload = {
    dishId: item.dishId, mealOrder: selectedMealOrder.value, mealOrderLabel: selectedMealOrderLabel.value,
    dishName: item.dishName, detail: item.detail, mealType: item.mealType, flavorTags: item.flavorTags,
    score: item.score, explainReason: item.explainReason, fallbackLevel: item.fallbackLevel ?? 0,
    flightNumber: currentFlight.value?.flightNumber, departure: currentFlight.value?.departure,
    destination: currentFlight.value?.destination, selectionDeadline: currentFlight.value?.selectionDeadline,
  }
  uni.navigateTo({ url: '/pages/recommendConfirm/recommendConfirm?payload=' + encodeURIComponent(JSON.stringify(payloadData)) })
}
onShow(() => { void loadData() })
</script>

<style scoped>
.page{--bg-a:#edf6ff;--bg-b:#f3fffa;--bg-c:#fff6ea;--ink-1:#132f4a;--ink-2:#486681;--line:#dbe8f5;--brand-1:#0ea5e9;--brand-2:#38bdf8;--accent:#f59e0b;--gold:#f59e0b;--silver:#94a3b8;--bronze:#d97706;min-height:100vh;padding:20rpx 24rpx 60rpx;background:linear-gradient(158deg,var(--bg-a) 0%,var(--bg-b) 50%,var(--bg-c) 100%);position:relative;overflow-x:hidden}
.aurora{position:absolute;z-index:0;border-radius:999rpx;filter:blur(20rpx);opacity:.42;pointer-events:none}
.aurora-a{width:260rpx;height:260rpx;right:-60rpx;top:80rpx;background:#7dd5ff}
.aurora-b{width:220rpx;height:220rpx;left:-60rpx;bottom:220rpx;background:#ffcf90}
.card{position:relative;z-index:2;border-radius:24rpx;padding:22rpx 24rpx;margin-bottom:16rpx;background:rgba(255,255,255,.94);border:1px solid var(--line);box-shadow:0 12rpx 32rpx rgba(15,23,42,.06);animation:rise-in 360ms ease both}
@keyframes rise-in{from{opacity:0;transform:translateY(10rpx)}to{opacity:1;transform:translateY(0)}}
.hero{background:linear-gradient(138deg,#0f172a 0%,#1e3a5f 52%,#0ea5e9 100%);color:#fff;border-color:rgba(255,255,255,.15)}
.hero-kicker{font-size:20rpx;letter-spacing:4rpx;opacity:.8;margin-bottom:6rpx}
.hero-top{display:flex;justify-content:space-between;align-items:flex-start}
.hero-title{font-size:38rpx;font-weight:800;letter-spacing:1rpx}
.hero-badge{padding:6rpx 18rpx;border-radius:999rpx;background:rgba(255,255,255,.2);font-size:22rpx;font-weight:700}
.hero-metrics{margin-top:18rpx;display:flex;gap:10rpx}
.metric{flex:1;border-radius:14rpx;background:rgba(255,255,255,.15);padding:12rpx 14rpx}
.metric-value{font-size:28rpx;font-weight:800}
.metric-label{margin-top:2rpx;font-size:20rpx;opacity:.85}
.rating-card{display:flex;justify-content:space-between;align-items:center;background:linear-gradient(130deg,#fff3dc 0%,#fff 44%,#ecf8ff 100%)}
.rating-title{color:#1f3955;font-size:28rpx;font-weight:700}
.rating-desc{margin-top:6rpx;color:#667f9a;font-size:22rpx}
.rating-btn{width:140rpx;height:64rpx;line-height:64rpx;border-radius:32rpx;background:linear-gradient(135deg,#f59e0b,#d97706);color:#fff;font-size:24rpx}
.flight-picker{display:flex;justify-content:space-between;align-items:center}
.flight-no{font-size:28rpx;font-weight:700;color:var(--ink-1)}
.flight-route{margin-top:4rpx;font-size:22rpx;color:var(--ink-2)}
.flight-picker-right{display:flex;align-items:center;gap:12rpx}
.deadline{font-size:21rpx;color:#d97706;font-weight:600}
.arrow{font-size:36rpx;color:#94a3b8}
.status-bar{margin-top:10rpx;display:flex;gap:16rpx}
.status-item{font-size:22rpx;color:#94a3b8}
.status-item.done{color:#10b981;font-weight:600}
.section-title{position:relative;z-index:2;display:flex;align-items:center;gap:8rpx;font-size:30rpx;font-weight:800;color:var(--ink-1);margin:8rpx 0 14rpx}
.title-icon{font-size:28rpx}
.section-chip{margin-left:auto;padding:4rpx 14rpx;border-radius:999rpx;background:#e8f6ff;color:var(--brand-1);font-size:21rpx;font-weight:600}
.meal-steps{position:relative;z-index:2;display:flex;align-items:center;justify-content:center;margin-bottom:20rpx;padding:16rpx 24rpx;background:rgba(255,255,255,.94);border-radius:24rpx;border:1px solid var(--line);box-shadow:0 8rpx 24rpx rgba(15,23,42,.04)}
.meal-step{display:flex;flex-direction:column;align-items:center;position:relative;flex:1;transition:all 200ms ease}
.step-dot{width:52rpx;height:52rpx;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24rpx;font-weight:800;background:#f1f5f9;color:#94a3b8;border:3rpx solid #e2e8f0;transition:all 240ms ease}
.meal-step.current .step-dot{background:linear-gradient(135deg,var(--brand-1),var(--brand-2));color:#fff;border-color:transparent;box-shadow:0 4rpx 16rpx rgba(14,165,233,.3);transform:scale(1.12)}
.meal-step.done .step-dot{background:#10b981;color:#fff;border-color:#10b981;font-size:22rpx}
.step-label{margin-top:8rpx;font-size:20rpx;color:#94a3b8;font-weight:600}
.meal-step.current .step-label{color:var(--brand-1)}
.meal-step.done .step-label{color:#10b981}
.step-line{position:absolute;top:26rpx;left:calc(50% + 30rpx);width:calc(100% - 60rpx);height:3rpx;background:#e2e8f0;z-index:0}
.top3-grid{position:relative;z-index:2;display:flex;gap:14rpx;overflow-x:auto;padding-bottom:4rpx}
.top3-card{flex-shrink:0;width:220rpx;border-radius:20rpx;background:#fff;overflow:hidden;box-shadow:0 10rpx 28rpx rgba(15,23,42,.08);border:2rpx solid var(--line);position:relative;transition:all 200ms ease;display:flex;flex-direction:column}
.top3-card:active{transform:scale(.97)}
.top3-card.rank-1{border-color:var(--gold);box-shadow:0 8rpx 24rpx rgba(245,158,11,.2)}
.top3-card.rank-2{border-color:var(--silver);box-shadow:0 8rpx 24rpx rgba(148,163,184,.15)}
.top3-card.rank-3{border-color:var(--bronze);box-shadow:0 8rpx 24rpx rgba(217,119,6,.12)}
.top3-card.selected{border-color:#10b981;box-shadow:0 8rpx 24rpx rgba(16,185,129,.18)}
.rank-badge{position:absolute;top:8rpx;left:8rpx;z-index:3;width:40rpx;height:40rpx;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:22rpx;font-weight:800;color:#fff}
.rank-badge.rank-1{background:linear-gradient(135deg,#f59e0b,#d97706);font-size:24rpx}
.rank-badge.rank-2{background:linear-gradient(135deg,#94a3b8,#64748b)}
.rank-badge.rank-3{background:linear-gradient(135deg,#d97706,#b45309)}
.top3-media{height:160rpx;position:relative;overflow:hidden;background:#f1f5f9}
.top3-img{width:100%;height:100%;display:block;object-fit:cover}
.top3-fade{position:absolute;left:0;right:0;bottom:0;height:60rpx;background:linear-gradient(transparent,rgba(0,0,0,.25))}
.top3-info{padding:14rpx 14rpx 12rpx;flex:1;display:flex;flex-direction:column}
.top3-name{font-size:26rpx;font-weight:800;color:var(--ink-1);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.top3-tags{margin-top:6rpx;display:flex;gap:6rpx}
.t3-tag{padding:2rpx 10rpx;border-radius:999rpx;font-size:19rpx;background:#f0f7ff;color:#3b82f6}
.top3-score-bar{margin-top:8rpx;height:6rpx;background:#e2e8f0;border-radius:3rpx;overflow:hidden}
.top3-score-fill{height:100%;border-radius:3rpx;background:linear-gradient(90deg,var(--brand-2),var(--brand-1))}
.top3-reason{margin-top:6rpx;font-size:19rpx;color:#64748b}
.top3-btn{margin-top:auto;padding:10rpx 0;border-radius:14rpx;background:linear-gradient(135deg,var(--brand-1),var(--brand-2));color:#fff;font-size:24rpx;font-weight:700;text-align:center}
.top3-btn.active{background:#e2e8f0;color:#64748b}
.flavor-bar{position:relative;z-index:2;white-space:nowrap;margin-bottom:16rpx;padding:4rpx 0}
.flavor-tag{display:inline-block;margin-right:12rpx;padding:10rpx 22rpx;border-radius:999rpx;border:1rpx solid #cbd5e1;color:#475569;background:#fff;font-size:23rpx;font-weight:600;transition:all 160ms ease}
.flavor-tag.active{border-color:transparent;background:linear-gradient(135deg,var(--brand-1),var(--brand-2));color:#fff}
.dish-grid{position:relative;z-index:2;display:grid;grid-template-columns:1fr 1fr;gap:14rpx}
.grid-card{background:#fff;border-radius:20rpx;overflow:hidden;border:1rpx solid var(--line);box-shadow:0 6rpx 20rpx rgba(15,23,42,.05);transition:all 180ms ease}
.grid-card:active{transform:scale(.97)}
.grid-card.selected{border-color:#10b981}
.grid-media{height:150rpx;position:relative;overflow:hidden;background:#f1f5f9}
.grid-img{width:100%;height:100%;display:block;object-fit:cover}
.grid-check{position:absolute;top:8rpx;right:8rpx;width:36rpx;height:36rpx;border-radius:50%;background:#10b981;color:#fff;display:flex;align-items:center;justify-content:center;font-size:20rpx;font-weight:800}
.grid-info{padding:12rpx 14rpx 14rpx}
.grid-name{font-size:24rpx;font-weight:700;color:var(--ink-1);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.grid-tags{margin-top:6rpx;display:flex;gap:4rpx;flex-wrap:wrap}
.g-tag{padding:2rpx 8rpx;border-radius:8rpx;font-size:18rpx;background:#f0f7ff;color:#3b82f6}
.grid-empty{position:relative;z-index:2;text-align:center;padding:40rpx;color:#94a3b8;font-size:24rpx}
.empty-card{border-style:dashed}
.empty-title{color:#1f3d58;font-size:28rpx;font-weight:700}
.empty-desc{margin-top:6rpx;color:#7891a8;font-size:23rpx}
.btn{border-radius:14rpx;background:linear-gradient(135deg,var(--brand-1),var(--brand-2));color:#fff;font-size:26rpx}
.btn.ghost{background:#f3f7fb;color:#4e6883;border:1px solid #d9e4ef}
</style>
