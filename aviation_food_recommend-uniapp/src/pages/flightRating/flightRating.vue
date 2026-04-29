<template>
  <view class="page">
    <view class="bg-orb orb-1"></view>
    <view class="bg-orb orb-2"></view>
    <view class="bg-orb orb-3"></view>

    <!-- 概览统计 -->
    <view class="overview-row">
      <view class="stat-card" @click="scrollToPending">
        <view class="stat-ring pending-ring">
          <text class="stat-num">{{ pendingList.length }}</text>
        </view>
        <text class="stat-label">待评分</text>
      </view>
      <view class="stat-card">
        <view class="stat-ring history-ring">
          <text class="stat-num">{{ ratingHistory.length }}</text>
        </view>
        <text class="stat-label">评分历史</text>
      </view>
      <view class="stat-card">
        <view class="stat-ring meal-ring">
          <text class="stat-num">{{ mergedSelections.length }}</text>
        </view>
        <text class="stat-label">已选餐食</text>
      </view>
    </view>

    <!-- 待评分列表 -->
    <view class="section-card" id="pendingSection" v-if="!selected">
      <view class="section-head">
        <view class="section-icon">📋</view>
        <view>
          <text class="section-title">待评分列表</text>
          <text class="section-desc">选择航班进行航后服务评价</text>
        </view>
        <view class="count-chip">{{ pendingList.length }} 条</view>
      </view>

      <view class="pending-list" v-if="pendingList.length">
        <view
          class="pending-item"
          v-for="item in pendingList"
          :key="item.flightId"
          @click="enterRating(item)"
        >
          <view class="pending-left">
            <view class="pending-flight">{{ item.flightNumber || '当前航班' }}</view>
            <view class="pending-route">
              <text>{{ item.departure || '-' }}</text>
              <text class="route-arrow">→</text>
              <text>{{ item.destination || '-' }}</text>
            </view>
          </view>
          <view class="pending-right">
            <text class="pending-time" v-if="item.arrivalTime">{{ formatDate(item.arrivalTime) }}</text>
            <view class="rating-trigger">去评分 ›</view>
          </view>
        </view>
      </view>

      <view class="empty-state" v-else>
        <view class="empty-icon">✨</view>
        <view class="empty-title">暂无待评分航班</view>
        <view class="empty-desc">完成飞行后，待评分项会出现</view>
      </view>
    </view>

    <!-- 评分表单 -->
    <view class="section-card" v-if="selected">
      <view class="section-head">
        <view class="section-icon">⭐</view>
        <view>
          <text class="section-title">航后反馈</text>
          <text class="section-desc">对本次航班服务进行评价</text>
        </view>
      </view>

      <view class="flight-hero">
        <view class="hero-flight-no">{{ selected.flightNumber || '当前航班' }}</view>
        <view class="hero-route">{{ selected.departure || '-' }} → {{ selected.destination || '-' }}</view>
        <view class="hero-time" v-if="selected.arrivalTime">到达 {{ formatTime(selected.arrivalTime) }}</view>
      </view>

      <view class="rating-section">
        <text class="rating-prompt">轻触星星评分</text>
        <view class="star-row">
          <view
            v-for="star in 5"
            :key="star"
            class="star"
            :class="{ on: rating >= star }"
            @click="rating = star"
          >
            <text class="star-icon">{{ rating >= star ? '★' : '☆' }}</text>
            <text class="star-num">{{ star }}</text>
          </view>
        </view>
        <view class="rating-feeling">{{ ratingLabel }}</view>
      </view>

      <view class="btn-row">
        <button class="btn outline" :disabled="submitting" @click="backToList">返回列表</button>
        <button class="btn outline" :disabled="submitting" @click="skipNow">稍后再说</button>
        <button class="btn primary" :disabled="submitting" @click="submitRating">
          {{ submitting ? '提交中…' : '提交评分' }}
        </button>
      </view>
    </view>

    <!-- 评分历史 -->
    <view class="section-card" v-if="ratingHistory.length">
      <view class="section-head">
        <view class="section-icon">📝</view>
        <view>
          <text class="section-title">评分历史</text>
          <text class="section-desc">最近提交的服务评价</text>
        </view>
      </view>
      <view class="history-list">
        <view
          class="history-item"
          v-for="(h, idx) in ratingHistory"
          :key="h.ratingTaskId || h.logId || h.flightId"
          :class="{ 'history-item--expanded': ratingExpandedId === (h.logId || h.flightId) }"
          :style="{ animationDelay: `${idx * 60}ms` }"
          @click="toggleRatingDetail(h)"
        >
          <view class="h-top">
            <view class="h-left">
              <view class="h-stars">{{ '★'.repeat(h.ratingScore || 0) }}{{ '☆'.repeat(5 - (h.ratingScore || 0)) }}</view>
              <view class="h-flight">{{ h.flightNumber || `航班#${h.flightId || '-'}` }}</view>
              <view class="h-route">{{ h.departure || '-' }} → {{ h.destination || '-' }}</view>
            </view>
            <view class="h-right">
              <text class="h-score">{{ h.ratingScore || '-' }}</text>
              <text class="h-unit">分</text>
              <text class="h-expand-arrow">{{ ratingExpandedId === (h.logId || h.flightId) ? '▲' : '▼' }}</text>
            </view>
          </view>
          <!-- 展开：所选餐食详情 -->
          <view class="h-detail" v-if="ratingExpandedId === (h.logId || h.flightId)">
            <view class="detail-divider"></view>
            <view class="h-detail-loading" v-if="loadingRatingDetail === (h.logId || h.flightId)">加载中…</view>
            <template v-else-if="ratingDetailMap[h.logId || h.flightId]">
              <view class="dish-hero dish-hero--sm">
                <view class="dish-hero-icon">🍱</view>
                <view class="dish-hero-info">
                  <text class="dish-hero-label">本次所选餐食</text>
                  <text class="dish-hero-name">{{ getDishName(ratingDetailMap[h.logId || h.flightId].selectedDishId) }}</text>
                </view>
              </view>
              <view class="detail-section" v-if="ratingDetailMap[h.logId || h.flightId].dishNames">
                <text class="detail-label">推荐候选菜品</text>
                <view class="dish-chips">
                  <text
                    v-for="(name, did) in ratingDetailMap[h.logId || h.flightId].dishNames"
                    :key="did"
                    class="dish-chip"
                    :class="{ selected: Number(did) === ratingDetailMap[h.logId || h.flightId].selectedDishId }"
                  >{{ name }}</text>
                </view>
              </view>
              <view class="detail-section" v-if="ratingDetailMap[h.logId || h.flightId].algorithmType">
                <text class="detail-label">推荐算法</text>
                <view class="algo-tag">{{ ratingDetailMap[h.logId || h.flightId].algorithmType }}</view>
              </view>
            </template>
            <view class="h-detail-empty" v-else>暂无详情数据</view>
          </view>
        </view>
      </view>
    </view>

    <!-- 我的已选餐食：点击航班号可查看所选餐食 -->
    <view class="section-card meal-section" v-if="mergedSelections.length">
      <view class="section-head">
        <view class="section-icon">🍽️</view>
        <view>
          <text class="section-title">我的已选餐食</text>
          <text class="section-desc">点击航班号查看该次预选的餐食详情</text>
        </view>
      </view>

      <view class="meal-list">
        <view
          class="meal-card"
          v-for="(h, idx) in mergedSelections"
          :key="h.id || h.sourceLogId"
          :class="{ expanded: expandedId === (h.id || h.sourceLogId) }"
          :style="{ animationDelay: `${idx * 80}ms` }"
          @click="toggleExpand(h)"
        >
          <!-- 卡片头部 -->
          <view class="meal-header">
            <view class="meal-header-left">
              <!-- 航班号 -->
              <view class="meal-flight-row">
                <text class="meal-flight-no">{{ h.flight_number || h.flightNumber || `航班#${h.flight_id || '-'}` }}</text>
                <text class="expand-hint">{{ expandedId === (h.id || h.sourceLogId) ? '收起 ▲' : '点击查看餐食 ▼' }}</text>
              </view>
              <view class="meal-route-sm">{{ h.departure || '-' }} → {{ h.destination || '-' }}</view>
              <view class="meal-time-sm" v-if="h.create_time || h.createTime">{{ formatTime(h.create_time || h.createTime) }}</view>
            </view>
            <view class="meal-header-right">
              <view class="meal-status" :class="{ rated: h.ratingStatus === 'SUBMITTED' }">
                {{ h.ratingStatus === 'SUBMITTED' ? `已评 ${h.ratingScore || '-'}★` : '未评分' }}
              </view>
              <text class="expand-arrow" :class="{ rotated: expandedId === (h.id || h.sourceLogId) }">›</text>
            </view>
          </view>

          <!-- 展开详情：所选餐食 -->
          <view class="meal-detail" v-if="expandedId === (h.id || h.sourceLogId)">
            <view class="detail-divider"></view>

            <!-- 已选餐食名称 -->
            <view class="dish-hero">
              <view class="dish-hero-icon">🍱</view>
              <view class="dish-hero-info">
                <text class="dish-hero-label">本次所选餐食</text>
                <text class="dish-hero-name">{{ getDishName(h.selectedDishId) }}</text>
              </view>
              <view class="dish-hero-badge" v-if="h.ratingStatus === 'SUBMITTED'">
                {{ h.ratingScore || '-' }}★
              </view>
            </view>

            <!-- 推荐原因 -->
            <view class="detail-section" v-if="h.algorithm_type || h.algorithmType">
              <text class="detail-label">推荐算法</text>
              <view class="algo-tag">{{ h.algorithm_type || h.algorithmType }}</view>
            </view>

            <!-- 推荐列表中的所有菜品 -->
            <view class="detail-section">
              <text class="detail-label">本次推荐的候选菜品</text>
              <view class="dish-chips">
                <text
                  v-for="did in parseDishIds(h.recommended_dishes || h.recommendedDishes)"
                  :key="did"
                  class="dish-chip"
                  :class="{ selected: did === h.selectedDishId }"
                >{{ getDishName(did) }}</text>
              </view>
            </view>

            <!-- 分项得分按钮 -->
            <button
              class="breakdown-btn"
              :disabled="loadingBreakdown === (h.id || h.sourceLogId)"
              @click.stop="fetchBreakdown(h.id || h.sourceLogId)"
            >
              {{ loadingBreakdown === (h.id || h.sourceLogId) ? '计算中…' : (breakdownMap[h.id || h.sourceLogId] ? '收起分项得分' : '查看推荐分项得分') }}
            </button>

            <!-- 分项得分展示 -->
            <view class="breakdown-inline" v-if="breakdownMap[h.id || h.sourceLogId]">
              <view class="breakdown-title">算法分项分解 · PMFUP / PRMIDM / AMMBC</view>
              <view
                class="b-row"
                v-for="row in (breakdownMap[h.id || h.sourceLogId]?.breakdown || [])"
                :key="row.dishId"
              >
                <view class="b-dish-head">
                  <text class="b-dish-name">{{ row.dishName }}</text>
                  <text class="b-dish-selected" v-if="row.dishId === h.selectedDishId">已选</text>
                </view>
                <view class="b-bar-wrap">
                  <view class="b-bar"><view class="b-fill pmfup" :style="{ width: `${(row.pmfup || 0) * 100}%` }"></view></view>
                  <text class="b-label">PMFUP</text>
                  <text class="b-val">{{ (row.pmfup || 0).toFixed(3) }}</text>
                </view>
                <view class="b-bar-wrap">
                  <view class="b-bar"><view class="b-fill prmidm" :style="{ width: `${(row.prmidm || 0) * 100}%` }"></view></view>
                  <text class="b-label">PRMIDM</text>
                  <text class="b-val">{{ (row.prmidm || 0).toFixed(3) }}</text>
                </view>
                <view class="b-bar-wrap">
                  <view class="b-bar"><view class="b-fill ammbc" :style="{ width: `${(row.ammbc || 0) * 100}%` }"></view></view>
                  <text class="b-label">AMMBC</text>
                  <text class="b-val">{{ (row.ammbc || 0).toFixed(3) }}</text>
                </view>
                <view class="b-fused">
                  <text>融合得分</text>
                  <text class="b-fused-val">{{ (row.fused || 0).toFixed(4) }}</text>
                </view>
              </view>
            </view>
          </view>
        </view>
      </view>
    </view>

    <view class="bottom-spacer"></view>
  </view>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import {
  deferRecommendationAPI,
  getHistoryLogDetailAPI,
  getPendingRatingAPI,
  getRatingHistoryAPI,
  rateRecommendationAPI,
  getRecommendationHistoryAPI,
  getRecommendationHistoryBreakdownAPI,
  resolveDishNamesAPI,
} from '@/api/recommendation'
import type { PendingRatingInfo } from '@/types/aviation'

const pendingList = ref<PendingRatingInfo[]>([])
const selected = ref<Partial<PendingRatingInfo> | null>(null)
const rating = ref(5)
const submitting = ref(false)
const recHistory = ref<Record<string, any>[]>([])
const ratingHistory = ref<Record<string, any>[]>([])
const mergedSelections = ref<Record<string, any>[]>([])
const expandedId = ref<number | null>(null)
const loadingBreakdown = ref<number | null>(null)
const breakdownMap = reactive<Record<string, any>>({})
const dishNameMap = ref<Record<number, string>>({})
const ratingExpandedId = ref<number | null>(null)
const loadingRatingDetail = ref<number | null>(null)
const ratingDetailMap = reactive<Record<string, any>>({})

const ratingLabel = computed(() => {
  const map: Record<number, string> = {
    1: '较不满意', 2: '有待改进', 3: '整体一般', 4: '比较满意', 5: '非常满意',
  }
  return map[rating.value] || '请选择评分'
})

const getDishName = (dishId?: number) => {
  if (dishId == null) return '未知餐食'
  return dishNameMap.value[dishId] || `餐食 #${dishId}`
}

const formatTime = (v?: string) => {
  if (!v) return '-'
  return String(v).replace('T', ' ').slice(0, 16)
}

const formatDate = (v?: string) => {
  if (!v) return ''
  return String(v).replace('T', ' ').slice(0, 16).slice(5, 16)
}

const parseDishIds = (raw?: string): number[] => {
  if (!raw) return []
  try {
    const arr = JSON.parse(raw)
    return Array.isArray(arr) ? arr.map(Number).filter(n => !isNaN(n)) : []
  } catch { return [] }
}

const resolveDishNames = async () => {
  const allIds = new Set<number>()
  for (const item of mergedSelections.value) {
    if (item.selectedDishId) allIds.add(item.selectedDishId)
    const ids = parseDishIds(item.recommended_dishes || item.recommendedDishes)
    ids.forEach(id => allIds.add(id))
  }
  if (!allIds.size) return
  try {
    const res = await resolveDishNamesAPI([...allIds])
    if (res.data) {
      dishNameMap.value = { ...dishNameMap.value, ...res.data }
    }
  } catch { /* 静默失败，模板会显示 fallback */ }
}

const loadPending = async () => {
  try {
    const res = await getPendingRatingAPI()
    pendingList.value = res.data || []
  } catch { pendingList.value = [] }
}

const loadHistory = async () => {
  try {
    const [histRes, ratingRes] = await Promise.all([
      getRecommendationHistoryAPI(),
      getRatingHistoryAPI().catch(() => ({ data: [] })),
    ])
    recHistory.value = histRes.data || []
    ratingHistory.value = ratingRes.data || []

    const rows = recHistory.value || []
    const ratings = ratingHistory.value || []
    const selections: Record<string, any>[] = []
    for (const row of rows) {
      const feedback = String(row.userFeedback ?? row.user_feedback ?? '')
      if (!feedback.startsWith('MANUAL_SELECTED') && !feedback.startsWith('AUTO_SELECTED_OVERDUE')) continue

      // 航班已到达则不再显示本次预选
      const arrivalRaw = row.arrival_time
      if (arrivalRaw) {
        const normalized = String(arrivalRaw).replace(' ', 'T')
        const arrival = new Date(normalized)
        if (!isNaN(arrival.getTime()) && arrival <= new Date()) continue
      }

      const m = feedback.match(/dishId=(\d+)/)
      const selectedDishId = m ? Number(m[1]) : undefined
      const srcId = row.id
      const matchedRating = ratings.find(r =>
        r.logId != null && srcId != null && Number(r.logId) === Number(srcId),
      )
      const hasLogRating = row.userRating != null || row.user_rating != null
      selections.push({
        ...row,
        sourceLogId: srcId,
        selectedDishId,
        ratingStatus: matchedRating ? 'SUBMITTED' : (hasLogRating ? 'SUBMITTED' : undefined),
        ratingScore: matchedRating ? matchedRating.ratingScore : (row.userRating || row.user_rating),
      })
    }
    mergedSelections.value = selections
    // 异步解析菜品名
    void resolveDishNames()
  } catch { recHistory.value = [] }
}

const toggleExpand = (h: Record<string, any>) => {
  const id = h.id || h.sourceLogId
  if (expandedId.value === id) {
    expandedId.value = null
  } else {
    expandedId.value = id
    // 自动拉取分项得分
    if (!breakdownMap[id]) {
      void fetchBreakdown(id)
    }
  }
}

const fetchBreakdown = async (logId?: number) => {
  if (!logId || loadingBreakdown.value === logId) return
  if (breakdownMap[logId]) {
    delete breakdownMap[logId]
    return
  }
  loadingBreakdown.value = logId
  try {
    const res = await getRecommendationHistoryBreakdownAPI(logId)
    breakdownMap[logId] = res.data || null
  } catch {
    /* 静默失败，模板会保持为空或上次缓存 */
  } finally {
    loadingBreakdown.value = null
  }
}

const toggleRatingDetail = async (h: Record<string, any>) => {
  const key = h.logId || h.flightId
  if (!key) return
  if (ratingExpandedId.value === key) {
    ratingExpandedId.value = null
    return
  }
  ratingExpandedId.value = key
  if (ratingDetailMap[key]) return
  loadingRatingDetail.value = key
  try {
    const res = await getHistoryLogDetailAPI(key)
    const detail = res.data || null
    if (detail) {
      ratingDetailMap[key] = detail
      // 合并菜品名到 dishNameMap
      if (detail.dishNames) {
        dishNameMap.value = { ...dishNameMap.value, ...detail.dishNames }
      }
    }
  } catch {
    /* 静默失败 */
  } finally {
    loadingRatingDetail.value = null
  }
}

const enterRating = (item: Partial<PendingRatingInfo>) => {
  selected.value = item
  rating.value = 5
}

const backToList = () => { selected.value = null }

const removeRatedFlight = (flightId?: number) => {
  if (!flightId) return
  pendingList.value = pendingList.value.filter(item => item.flightId !== flightId)
}

const submitRating = async () => {
  if (!selected.value?.flightId || submitting.value) return
  submitting.value = true
  try {
    await rateRecommendationAPI(rating.value, selected.value.flightId)
    removeRatedFlight(selected.value.flightId)
    selected.value = null
    await loadHistory()
    uni.showToast({ title: '感谢评分，已提交', icon: 'none' })
  } catch (error) {
    const msg = typeof error === 'object' && error && 'msg' in error
      ? String((error as any).msg || '评分提交失败') : '评分提交失败'
    uni.showToast({ title: msg, icon: 'none' })
  } finally { submitting.value = false }
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
    const msg = typeof error === 'object' && error && 'msg' in error
      ? String((error as any).msg || '延期失败') : '延期失败'
    uni.showToast({ title: msg, icon: 'none' })
  } finally { submitting.value = false }
}

const scrollToPending = () => {
  // tab 切换时会刷新，这里仅标记
  selected.value = null
}

onShow(() => {
  selected.value = null
  expandedId.value = null
  ratingExpandedId.value = null
  Object.keys(breakdownMap).forEach(k => delete breakdownMap[k])
  Object.keys(ratingDetailMap).forEach(k => delete ratingDetailMap[k])
  void loadPending()
  void loadHistory()
})
</script>

<style scoped>
/* ===== 基础页面 ===== */
.page {
  box-sizing: border-box;
  min-height: 100vh;
  padding: 20rpx 24rpx 200rpx;
  background: linear-gradient(168deg, #f0f4fb 0%, #eaf2fa 30%, #fdf7ed 70%, #faf5ea 100%);
  position: relative;
  overflow-x: hidden;
  overflow-y: auto;
  font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Helvetica Neue', sans-serif;
}

.bg-orb {
  position: fixed; border-radius: 999rpx; filter: blur(80rpx); opacity: 0.38; pointer-events: none;
}
.orb-1 { width: 340rpx; height: 340rpx; right: -100rpx; top: 80rpx; background: #ffd36c; }
.orb-2 { width: 280rpx; height: 280rpx; left: -80rpx; top: 420rpx; background: #7acfff; }
.orb-3 { width: 300rpx; height: 300rpx; right: -60rpx; bottom: 200rpx; background: #c4b5fd; opacity: 0.28; }

/* ===== 统计 ===== */
.overview-row { display: flex; gap: 16rpx; margin-bottom: 22rpx; position: relative; z-index: 2; }
.stat-card { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 10rpx; }
.stat-ring {
  width: 100rpx; height: 100rpx; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  background: rgba(255,255,255,0.82);
  box-shadow: 0 8rpx 22rpx rgba(18,52,86,0.08);
  backdrop-filter: blur(8rpx);
}
.stat-num { font-size: 38rpx; font-weight: 800; letter-spacing: -1rpx; }
.pending-ring .stat-num { color: #e88a30; }
.history-ring .stat-num { color: #2f8fcf; }
.meal-ring .stat-num { color: #3da56e; }
.stat-label { font-size: 22rpx; color: #5c6f85; font-weight: 500; }

/* ===== 通用卡片 ===== */
.section-card {
  position: relative; z-index: 2; margin-bottom: 20rpx;
  background: rgba(255,255,255,0.84); border-radius: 26rpx; padding: 28rpx 26rpx;
  border: 1px solid rgba(255,255,255,0.6);
  box-shadow: 0 12rpx 36rpx rgba(18,48,78,0.07);
  backdrop-filter: blur(12rpx);
  animation: cardIn 420ms ease both;
}
@keyframes cardIn { from { opacity: 0; transform: translateY(16rpx); } to { opacity: 1; transform: translateY(0); } }

.section-head { display: flex; align-items: center; gap: 14rpx; margin-bottom: 22rpx; }
.section-icon {
  width: 60rpx; height: 60rpx; border-radius: 18rpx;
  background: linear-gradient(135deg, #f0f6ff 0%, #e8f0fc 100%);
  display: flex; align-items: center; justify-content: center; font-size: 30rpx;
}
.section-title { display: block; font-size: 30rpx; font-weight: 800; color: #1a3552; line-height: 1.3; }
.section-desc { display: block; font-size: 22rpx; color: #70859b; margin-top: 2rpx; }
.count-chip {
  margin-left: auto; padding: 6rpx 16rpx; border-radius: 999rpx;
  font-size: 22rpx; color: #3e688f; background: #eaf3fd;
  border: 1px solid #d4e5f8; font-weight: 600;
}

/* ===== 待评分列表 ===== */
.pending-list { display: flex; flex-direction: column; gap: 12rpx; }
.pending-item {
  display: flex; align-items: center; justify-content: space-between;
  padding: 20rpx 22rpx; border-radius: 20rpx;
  background: linear-gradient(135deg, #fafcff 0%, #f3f8fe 100%);
  border: 1px solid #e6eff9;
  transition: all 140ms ease;
}
.pending-item:active { background: linear-gradient(135deg, #eef5fd 0%, #e0ecf8 100%); transform: scale(0.986); }
.pending-flight { font-size: 27rpx; font-weight: 700; color: #163350; }
.pending-route { margin-top: 4rpx; font-size: 23rpx; color: #587592; }
.route-arrow { margin: 0 6rpx; color: #8ca8c4; }
.pending-right { display: flex; flex-direction: column; align-items: flex-end; gap: 6rpx; }
.pending-time { font-size: 21rpx; color: #849bb3; }
.rating-trigger {
  padding: 8rpx 18rpx; border-radius: 10rpx;
  background: linear-gradient(135deg, #2f8fcf 0%, #1a7cc0 100%);
  color: #fff; font-size: 22rpx; font-weight: 600;
  box-shadow: 0 6rpx 14rpx rgba(26,124,192,0.22);
}

/* ===== 空状态 ===== */
.empty-state { padding: 36rpx 20rpx 20rpx; text-align: center; }
.empty-icon { font-size: 54rpx; margin-bottom: 12rpx; }
.empty-title { font-size: 28rpx; font-weight: 700; color: #2c4a68; }
.empty-desc { margin-top: 6rpx; font-size: 23rpx; color: #7f93a9; }

/* ===== 评分表单 ===== */
.flight-hero {
  border-radius: 20rpx; padding: 24rpx;
  background: linear-gradient(135deg, #1e3b58 0%, #1a4a78 60%, #16568a 100%);
  color: #fff; margin-bottom: 24rpx;
}
.hero-flight-no { font-size: 34rpx; font-weight: 800; }
.hero-route { margin-top: 8rpx; font-size: 26rpx; opacity: 0.9; }
.hero-time { margin-top: 6rpx; font-size: 22rpx; opacity: 0.7; }

.rating-section { text-align: center; padding: 16rpx 0; }
.rating-prompt { font-size: 24rpx; color: #5a738f; margin-bottom: 20rpx; display: block; }
.star-row { display: flex; justify-content: center; gap: 18rpx; }
.star { display: flex; flex-direction: column; align-items: center; gap: 4rpx; transition: transform 140ms ease; }
.star:active { transform: scale(1.12); }
.star-icon { font-size: 58rpx; color: #cdd8e6; transition: color 160ms ease; }
.star.on .star-icon { color: #f5a623; }
.star-num { font-size: 20rpx; color: #8b9db5; }
.rating-feeling { margin-top: 18rpx; font-size: 30rpx; font-weight: 700; color: #1f4567; }

.btn-row { display: flex; gap: 14rpx; margin-top: 28rpx; }
.btn {
  flex: 1; height: 84rpx; line-height: 84rpx; border-radius: 18rpx;
  font-size: 26rpx; font-weight: 600; border: none; padding: 0;
}
.btn.primary {
  background: linear-gradient(135deg, #1f8ad8 0%, #0ca3dd 100%);
  color: #fff; box-shadow: 0 10rpx 22rpx rgba(18,130,208,0.26);
}
.btn.outline { background: #fff; color: #3e668b; border: 1px solid #d9e6f3; }

/* ===== 评分历史 ===== */
.history-list { display: flex; flex-direction: column; gap: 10rpx; }
.history-item {
  display: flex; flex-direction: column;
  padding: 18rpx 20rpx; border-radius: 18rpx;
  background: linear-gradient(130deg, #fefefe 0%, #f8fafe 100%);
  border: 1px solid #ecf2f8;
  animation: fadeSlide 320ms ease both;
  transition: all 180ms ease;
}
.history-item:active { background: linear-gradient(130deg, #f4f8fd 0%, #edf3fa 100%); transform: scale(0.986); }
.history-item--expanded { border-color: #c8daea; box-shadow: 0 4rpx 16rpx rgba(18,52,86,0.06); }
@keyframes fadeSlide { from { opacity: 0; transform: translateX(-12rpx); } to { opacity: 1; transform: translateX(0); } }
.h-top { display: flex; align-items: center; justify-content: space-between; width: 100%; }
.h-left { flex: 1; }
.h-stars { font-size: 22rpx; color: #f5a623; letter-spacing: 2rpx; margin-bottom: 4rpx; }
.h-flight { font-size: 25rpx; font-weight: 700; color: #1d3b58; }
.h-route { margin-top: 2rpx; font-size: 21rpx; color: #6f869f; }
.h-right { display: flex; align-items: center; gap: 8rpx; }
.h-score { font-size: 44rpx; font-weight: 800; color: #276aae; line-height: 1; }
.h-unit { font-size: 22rpx; color: #7d97b3; }
.h-expand-arrow { font-size: 20rpx; color: #96afc7; margin-left: 2rpx; }

/* 评分历史展开详情 */
.h-detail { padding-top: 12rpx; width: 100%; }
.h-detail-loading { text-align: center; font-size: 22rpx; color: #889db5; padding: 16rpx 0; }
.h-detail-empty { text-align: center; font-size: 22rpx; color: #a0b2c5; padding: 16rpx 0; }
.dish-hero--sm { padding: 14rpx 16rpx; margin-bottom: 12rpx; }
.dish-hero--sm .dish-hero-icon { font-size: 36rpx; }
.dish-hero--sm .dish-hero-name { font-size: 26rpx; }

/* ===== 已选餐食卡片 ===== */
.meal-list { display: flex; flex-direction: column; gap: 14rpx; }
.meal-card {
  border-radius: 22rpx;
  background: linear-gradient(145deg, #ffffff 0%, #f9fcff 100%);
  border: 1px solid #eaf1f9;
  overflow: hidden;
  transition: all 220ms ease;
  animation: fadeSlide 360ms ease both;
}
.meal-card:active { background: linear-gradient(145deg, #f3f8fd 0%, #ebf4fc 100%); transform: scale(0.985); }
.meal-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 20rpx 22rpx;
}
.meal-header-left { flex: 1; }
.meal-flight-row {
  display: flex; align-items: center; gap: 10rpx;
  transition: opacity 140ms ease;
}
.meal-flight-row:active { opacity: 0.7; }
.meal-flight-no {
  font-size: 28rpx; font-weight: 800; color: #1a4f8a;
  padding: 4rpx 14rpx;
  border-radius: 10rpx;
  background: linear-gradient(135deg, #eaf5fe 0%, #dae9f8 100%);
}
.expand-hint {
  font-size: 21rpx; color: #6b9fd1; font-weight: 500;
}
.meal-route-sm { margin-top: 8rpx; font-size: 23rpx; color: #5d7894; }
.meal-time-sm { margin-top: 2rpx; font-size: 21rpx; color: #8da1b8; }
.meal-header-right { display: flex; align-items: center; gap: 12rpx; }
.meal-status {
  padding: 6rpx 16rpx; border-radius: 999rpx;
  font-size: 21rpx; font-weight: 600;
  background: #fef4e8; color: #c07d30;
}
.meal-status.rated { background: #e9f7ef; color: #34855d; }
.expand-arrow {
  font-size: 36rpx; color: #a6bdd4;
  transition: transform 240ms ease; line-height: 1;
}
.expand-arrow.rotated { transform: rotate(90deg); }

/* 展开详情 */
.meal-detail { padding: 0 22rpx 24rpx; }
.detail-divider {
  height: 1px;
  background: linear-gradient(90deg, #e2ebf5 0%, #ecf2f9 50%, #e2ebf5 100%);
  margin-bottom: 18rpx;
}

/* 已选餐食 hero */
.dish-hero {
  display: flex; align-items: center; gap: 16rpx;
  padding: 20rpx; border-radius: 18rpx;
  background: linear-gradient(135deg, #f0f9f0 0%, #e6f4ea 50%, #f8fff8 100%);
  border: 1px solid #d4ead8;
  margin-bottom: 20rpx;
}
.dish-hero-icon { font-size: 44rpx; }
.dish-hero-info { flex: 1; }
.dish-hero-label { display: block; font-size: 21rpx; color: #5f9170; }
.dish-hero-name { display: block; margin-top: 4rpx; font-size: 30rpx; font-weight: 800; color: #1a4a2e; }
.dish-hero-badge {
  padding: 8rpx 16rpx; border-radius: 12rpx;
  background: linear-gradient(135deg, #ffb733 0%, #f5951e 100%);
  color: #fff; font-size: 24rpx; font-weight: 700;
}

.detail-section { margin-bottom: 16rpx; }
.detail-label {
  display: block; font-size: 22rpx; color: #889db5;
  margin-bottom: 8rpx; font-weight: 500;
  letter-spacing: 1rpx;
}
.algo-tag {
  display: inline-block; padding: 6rpx 16rpx; border-radius: 999rpx;
  font-size: 22rpx; color: #3e6590; background: #edf4fd;
  border: 1px solid #d6e6f8; font-family: monospace;
}

/* 菜品标签 */
.dish-chips { display: flex; flex-wrap: wrap; gap: 10rpx; }
.dish-chip {
  padding: 8rpx 16rpx; border-radius: 12rpx;
  font-size: 22rpx; color: #3e5f82;
  background: #f2f6fb; border: 1px solid #dfe9f4;
  transition: all 140ms ease;
}
.dish-chip.selected {
  color: #fff;
  background: linear-gradient(135deg, #2f9e5a 0%, #238b48 100%);
  border-color: #1f7a3e;
  font-weight: 700;
  box-shadow: 0 4rpx 12rpx rgba(35,139,72,0.24);
}

.breakdown-btn {
  width: 100%; height: 72rpx; line-height: 72rpx;
  border-radius: 14rpx;
  background: linear-gradient(135deg, #2b8fd0 0%, #1b79bb 100%);
  color: #fff; font-size: 24rpx; font-weight: 600;
  margin-top: 8rpx;
  box-shadow: 0 8rpx 18rpx rgba(22,116,186,0.2);
}

/* 分项得分 */
.breakdown-inline {
  margin-top: 20rpx; padding: 20rpx; border-radius: 16rpx;
  background: #f8fafe; border: 1px solid #e8f0f8;
}
.breakdown-title {
  font-size: 24rpx; font-weight: 700; color: #1b3e5e;
  margin-bottom: 16rpx; text-align: center;
}
.b-row {
  padding: 14rpx 12rpx; border-radius: 12rpx;
  background: #fff; margin-bottom: 10rpx; border: 1px solid #eef3f9;
}
.b-dish-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10rpx; }
.b-dish-name { font-size: 24rpx; font-weight: 700; color: #143a60; }
.b-dish-selected {
  padding: 2rpx 12rpx; border-radius: 999rpx;
  font-size: 20rpx; color: #2f9e5a; background: #e9f7ef;
  font-weight: 600;
}
.b-bar-wrap { display: flex; align-items: center; gap: 10rpx; margin-bottom: 6rpx; }
.b-bar { flex: 1; height: 10rpx; background: #e8eff7; border-radius: 999rpx; overflow: hidden; }
.b-fill { height: 100%; border-radius: inherit; transition: width 500ms ease; }
.b-fill.pmfup { background: linear-gradient(90deg, #58a6ff, #3b8fef); }
.b-fill.prmidm { background: linear-gradient(90deg, #f0883e, #e07028); }
.b-fill.ammbc { background: linear-gradient(90deg, #3fb950, #2ea043); }
.b-label { font-size: 20rpx; color: #6b84a0; width: 90rpx; font-weight: 500; }
.b-val { font-size: 21rpx; color: #1d4264; font-weight: 600; width: 80rpx; text-align: right; }
.b-fused {
  display: flex; justify-content: space-between; align-items: center;
  margin-top: 10rpx; padding-top: 10rpx;
  border-top: 1px dashed #dbe4f0;
  font-size: 22rpx; color: #4a6682;
}
.b-fused-val { font-size: 28rpx; font-weight: 800; color: #1b6db5; }

.bottom-spacer { height: 40rpx; }
</style>
