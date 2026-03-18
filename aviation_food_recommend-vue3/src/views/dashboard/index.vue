<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, shallowRef } from 'vue'
import { useRouter } from 'vue-router'
import * as echarts from 'echarts'
import type { ECharts, EChartsOption } from 'echarts'
import { getRecommendationDashboardAPI, getRecommendationTopAPI } from '@/api/recommendation'
import { getAnnouncementListAPI, getFlightListAPI } from '@/api/flight'
import type { AnnouncementItem, DashboardStats } from '@/types/aviation'

const router = useRouter()

const loading = ref(false)
const dashboard = ref<DashboardStats>({
  recommendCount: 0,
  preferenceUserCount: 0,
  selectionCount: 0,
  avgRating: 0,
})
const flightCount = ref(0)
const announcementCount = ref(0)
const recentAnnouncements = ref<AnnouncementItem[]>([])
const topDishes = ref<Array<{ dishId: number; dishName: string; selectCount: number }>>([])
const range = ref<'7' | '30' | 'all'>('7')
const page = ref(1)
const pageSize = ref(10)

const barRef = ref<HTMLDivElement | null>(null)
const pieRef = ref<HTMLDivElement | null>(null)
const barChart = shallowRef<ECharts | null>(null)
const pieChart = shallowRef<ECharts | null>(null)

const pagedAnnouncements = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return recentAnnouncements.value.slice(start, start + pageSize.value)
})

const daysParam = computed(() => {
  if (range.value === '7') return 7
  if (range.value === '30') return 30
  return undefined
})

const resizeCharts = () => {
  barChart.value?.resize()
  pieChart.value?.resize()
}

const buildBarOption = (): EChartsOption => ({
  tooltip: { trigger: 'axis' },
  grid: { left: 24, right: 24, top: 24, bottom: 70, containLabel: true },
  xAxis: {
    type: 'category',
    data: topDishes.value.map((x) => x.dishName),
    axisLabel: { interval: 0, rotate: 18, color: '#5d7288' },
  },
  yAxis: {
    type: 'value',
    axisLabel: { color: '#5d7288' },
  },
  series: [
    {
      type: 'bar',
      barWidth: 26,
      data: topDishes.value.map((x) => x.selectCount),
      itemStyle: {
        borderRadius: [8, 8, 0, 0],
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: '#39beff' },
          { offset: 1, color: '#0f9bff' },
        ]),
      },
    },
  ],
})

const buildPieOption = (): EChartsOption => ({
  tooltip: {
    trigger: 'item',
    formatter: '{b}<br/>预选数量：{c} ({d}%)',
  },
  legend: {
    type: 'scroll',
    bottom: 0,
  },
  series: [
    {
      type: 'pie',
      radius: ['44%', '68%'],
      center: ['50%', '42%'],
      itemStyle: {
        borderColor: '#fff',
        borderWidth: 2,
        borderRadius: 8,
      },
      data: topDishes.value.map((x) => ({ name: x.dishName, value: x.selectCount })),
    },
  ],
})

const renderCharts = () => {
  if (!barRef.value || !pieRef.value) return
  if (!barChart.value) barChart.value = echarts.init(barRef.value)
  if (!pieChart.value) pieChart.value = echarts.init(pieRef.value)

  if (!topDishes.value.length) {
    const empty: EChartsOption = {
      title: {
        text: '暂无预选数据',
        left: 'center',
        top: 'center',
        textStyle: { color: '#8ea5bb', fontSize: 16, fontWeight: 500 },
      },
    }
    barChart.value.setOption(empty, true)
    pieChart.value.setOption(empty, true)
    return
  }

  barChart.value.setOption(buildBarOption(), true)
  pieChart.value.setOption(buildPieOption(), true)
}

const loadTop = async () => {
  const topRes = await getRecommendationTopAPI(8, daysParam.value)
  if (topRes.data.code === 0) {
    topDishes.value = topRes.data.data || []
  } else {
    topDishes.value = []
  }
  await nextTick()
  renderCharts()
}

const loadData = async () => {
  loading.value = true
  try {
    const [dashRes, flightRes, annRes] = await Promise.all([
      getRecommendationDashboardAPI(),
      getFlightListAPI(),
      getAnnouncementListAPI(),
    ])

    if (dashRes.data.code === 0) {
      dashboard.value = dashRes.data.data || dashboard.value
    }
    if (flightRes.data.code === 0) {
      const flights = flightRes.data.data || []
      flightCount.value = flights.length
    }
    if (annRes.data.code === 0) {
      const announcements = annRes.data.data || []
      announcementCount.value = announcements.length
      recentAnnouncements.value = announcements
    }
    await loadTop()
  } finally {
    loading.value = false
  }
}

const onRangeChange = async () => {
  loading.value = true
  await loadTop()
  loading.value = false
}

onMounted(async () => {
  await loadData()
  window.addEventListener('resize', resizeCharts)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', resizeCharts)
  barChart.value?.dispose()
  pieChart.value?.dispose()
})
</script>

<template>
  <div class="aviation-dashboard" v-loading="loading">
    <el-row :gutter="16" class="top-cards">
      <el-col :span="6"><el-card>推荐请求总数：{{ dashboard.recommendCount }}</el-card></el-col>
      <el-col :span="6"><el-card>偏好用户数：{{ dashboard.preferenceUserCount }}</el-card></el-col>
      <el-col :span="6"><el-card>预选单数量：{{ dashboard.selectionCount }}</el-card></el-col>
      <el-col :span="6"><el-card>平均满意度：{{ Number(dashboard.avgRating || 0).toFixed(2) }}</el-card></el-col>
    </el-row>

    <el-row :gutter="16" class="top-cards">
      <el-col :span="12"><el-card>航班总数：{{ flightCount }}</el-card></el-col>
      <el-col :span="12"><el-card>公告总数：{{ announcementCount }}</el-card></el-col>
    </el-row>

    <el-row :gutter="16" class="top-cards">
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="header-row">
              <span>餐食预选数量（条形图）</span>
              <el-segmented
                v-model="range"
                :options="[
                  { label: '7天', value: '7' },
                  { label: '30天(1个月)', value: '30' },
                  { label: '全部', value: 'all' },
                ]"
                @change="onRangeChange"
              />
            </div>
          </template>
          <div ref="barRef" class="chart-box"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>
            <span>餐食预选百分比（扇形图）</span>
          </template>
          <div ref="pieRef" class="chart-box"></div>
        </el-card>
      </el-col>
    </el-row>

    <el-card>
      <template #header>
        <div class="header-row">
          <span>最近公告</span>
          <el-button type="primary" link @click="router.push('/preferences')">去公告管理</el-button>
        </div>
      </template>
      <el-table :data="pagedAnnouncements" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="title" label="标题" min-width="220" />
        <el-table-column prop="content" label="内容" min-width="420" show-overflow-tooltip />
        <template #empty>
          <el-empty description="暂无公告" />
        </template>
      </el-table>
      <el-pagination
        class="table-pagination"
        v-model:current-page="page"
        v-model:page-size="pageSize"
        :page-sizes="[10, 15, 20]"
        :total="recentAnnouncements.length"
        layout="total, sizes, prev, pager, next, jumper"
        background
      />
    </el-card>
  </div>
</template>

<style scoped>
.aviation-dashboard {
  padding: 20px;
}

.top-cards {
  margin-bottom: 16px;
}

.chart-box {
  width: 100%;
  height: 320px;
}

.table-pagination {
  margin-top: 14px;
  justify-content: flex-end;
}

.header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
