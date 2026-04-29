<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { getUserMealSelectionListAPI, getUserMealStatisticsAPI } from '@/api/userMeal'
import type { UserMealSelectionItem, UserMealStatistics } from '@/types/aviation'

const loading = ref(false)
const statisticsLoading = ref(false)
const list = ref<UserMealSelectionItem[]>([])
const queryForm = ref({
  flightNumber: '',
  name: '',
  idNumber: '',
  mealSelection: 'all',
})

const createEmptyStatistics = (): UserMealStatistics => ({
  flightNumber: '',
  totalOrders: 0,
  selectedOrders: 0,
  unselectedOrders: 0,
  unrecordedOrders: 0,
  totalDishDemand: 0,
  distinctDishCount: 0,
  dishDemandList: [],
})

const statistics = ref<UserMealStatistics>(createEmptyStatistics())
const page = ref(1)
const pageSize = ref(10)

const hasFlightNumber = computed(() => !!queryForm.value.flightNumber.trim())

const filteredList = computed(() => {
  if (queryForm.value.mealSelection === 'all') return list.value
  return list.value.filter((item) => {
    const hasSelection = Number(item.dishCount || 0) > 0
    return queryForm.value.mealSelection === 'selected' ? hasSelection : !hasSelection
  })
})

const pagedList = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return filteredList.value.slice(start, start + pageSize.value)
})

const loadStatistics = async () => {
  const flightNumber = queryForm.value.flightNumber.trim()
  if (!flightNumber) {
    statistics.value = createEmptyStatistics()
    return
  }
  statisticsLoading.value = true
  const { data: res } = await getUserMealStatisticsAPI(flightNumber)
  statisticsLoading.value = false
  if (res.code !== 0) {
    return
  }
  statistics.value = {
    ...createEmptyStatistics(),
    ...(res.data || {}),
    dishDemandList: res.data?.dishDemandList || [],
  }
}

const loadData = async () => {
  loading.value = true
  const { data: res } = await getUserMealSelectionListAPI({
    flightNumber: queryForm.value.flightNumber?.trim() || undefined,
    name: queryForm.value.name?.trim() || undefined,
    idNumber: queryForm.value.idNumber?.trim() || undefined,
  })
  loading.value = false
  if (res.code === 0) {
    list.value = res.data || []
  }
  await loadStatistics()
}

const search = async () => {
  page.value = 1
  await loadData()
}

const onMealSelectionChange = () => {
  page.value = 1
}

const reset = async () => {
  queryForm.value = {
    flightNumber: '',
    name: '',
    idNumber: '',
    mealSelection: 'all',
  }
  page.value = 1
  statistics.value = createEmptyStatistics()
  await loadData()
}

const formatOrderStatus = (status?: number) => {
  const map: Record<number, string> = {
    1: '待确认',
    2: '待处理',
    3: '已确认',
    4: '处理中',
    5: '自动分配',
    6: '已取消',
  }
  if (!status) return '-'
  return map[status] || `状态${status}`
}

const formatDishName = (dishName?: string) => {
  if (!dishName) return '-'
  const normalized = dishName
    .replace(/\[/g, '')
    .replace(/\]/g, '')
    .replace(/"/g, '')
    .trim()
  if (!normalized || normalized === '未记录具体餐食') {
    return '-'
  }
  const dishes = normalized
    .split(/[、,，]/)
    .map((item) => item.trim())
    .filter(Boolean)
  if (!dishes.length) return '-'
  if (dishes.length === 1) return dishes[0]
  return dishes.map((item, index) => `第${index + 1}餐：${item}`).join('；')
}

const statusTagType = (status?: number) => {
  if (status === 1) return 'info'
  if (status === 2) return 'primary'
  if (status === 3) return 'success'
  if (status === 4) return 'warning'
  if (status === 5) return 'warning'
  if (status === 6) return 'danger'
  return 'info'
}

onMounted(loadData)
</script>

<template>
  <div class="page">
    <el-card>
      <template #header>
        <div class="header-row">
          <span>用户餐食中心</span>
          <el-button @click="loadData">刷新</el-button>
        </div>
      </template>

      <el-form inline>
        <el-form-item label="航班号">
          <el-input v-model="queryForm.flightNumber" placeholder="请输入航班号" clearable />
        </el-form-item>
        <el-form-item label="姓名">
          <el-input v-model="queryForm.name" placeholder="请输入客户姓名" clearable />
        </el-form-item>
        <el-form-item label="身份证号">
          <el-input v-model="queryForm.idNumber" placeholder="请输入身份证号" clearable />
        </el-form-item>
        <el-form-item label="是否选餐">
          <el-select v-model="queryForm.mealSelection" style="width: 120px" @change="onMealSelectionChange">
            <el-option label="全部" value="all" />
            <el-option label="已选餐" value="selected" />
            <el-option label="未选餐" value="unselected" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="search">查询</el-button>
          <el-button @click="reset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-alert
        v-if="!hasFlightNumber"
        title="输入航班号后可查看本航班餐食需求统计"
        type="info"
        :closable="false"
        class="stats-hint"
      />

      <div v-else class="stats-wrapper" v-loading="statisticsLoading">
        <el-row :gutter="12" class="stats-cards">
          <el-col :xs="12" :sm="8" :md="4">
            <el-card class="stats-card" shadow="hover">
              <div class="stats-label">选餐单总数</div>
              <div class="stats-value">{{ statistics.totalOrders }}</div>
            </el-card>
          </el-col>
          <el-col :xs="12" :sm="8" :md="4">
            <el-card class="stats-card" shadow="hover">
              <div class="stats-label">已记录餐食</div>
              <div class="stats-value">{{ statistics.selectedOrders }}</div>
            </el-card>
          </el-col>
          <el-col :xs="12" :sm="8" :md="4">
            <el-card class="stats-card" shadow="hover">
              <div class="stats-label">未记录餐食</div>
              <div class="stats-value">{{ statistics.unselectedOrders }}</div>
            </el-card>
          </el-col>
          <el-col :xs="12" :sm="8" :md="4">
            <el-card class="stats-card" shadow="hover">
              <div class="stats-label">总餐食需求数</div>
              <div class="stats-value">{{ statistics.totalDishDemand }}</div>
            </el-card>
          </el-col>
          <el-col :xs="12" :sm="8" :md="4">
            <el-card class="stats-card" shadow="hover">
              <div class="stats-label">涉及餐食种类</div>
              <div class="stats-value">{{ statistics.distinctDishCount }}</div>
            </el-card>
          </el-col>
          <el-col :xs="12" :sm="8" :md="4">
            <el-card class="stats-card" shadow="hover">
              <div class="stats-label">未记录明细单</div>
              <div class="stats-value">{{ statistics.unrecordedOrders }}</div>
            </el-card>
          </el-col>
        </el-row>

        <el-card class="stats-detail" shadow="never">
          <template #header>
            <div class="stats-detail-header">本航班餐食需求明细</div>
          </template>
          <el-table :data="statistics.dishDemandList" stripe size="small" max-height="260">
            <el-table-column type="index" width="56" label="#" />
            <el-table-column prop="dishName" label="餐食名称" min-width="220" />
            <el-table-column prop="demandCount" label="需求份数" width="120" />
            <template #empty>
              <el-empty description="本航班暂无可统计的餐食需求" />
            </template>
          </el-table>
        </el-card>
      </div>

      <el-table :data="pagedList" border stripe v-loading="loading">
        <el-table-column prop="orderNumber" label="选餐单号" min-width="170" />
        <el-table-column prop="flightNumber" label="航班号" width="120" />
        <el-table-column label="航线" min-width="180">
          <template #default="scope">
            {{ scope.row.departure || '-' }} → {{ scope.row.destination || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="userName" label="客户姓名" width="110" />
        <el-table-column prop="idNumber" label="身份证号" min-width="180" />
        <el-table-column label="所选餐食" min-width="150">
          <template #default="scope">
            {{ formatDishName(scope.row.dishName) }}
          </template>
        </el-table-column>
        <el-table-column prop="dishCount" label="数量" width="80" />
        <el-table-column label="选餐状态" width="100">
          <template #default="scope">
            <el-tag :type="statusTagType(scope.row.orderStatus)">{{ formatOrderStatus(scope.row.orderStatus) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="orderTime" label="选餐时间" min-width="170" />
        <template #empty>
          <el-empty description="暂无符合条件的用户选餐记录" />
        </template>
      </el-table>
      <el-pagination
        class="table-pagination"
        v-model:current-page="page"
        v-model:page-size="pageSize"
        :page-sizes="[10, 15, 20]"
        :total="filteredList.length"
        layout="total, sizes, prev, pager, next, jumper"
        background
      />
    </el-card>
  </div>
</template>

<style scoped>
.page {
  padding: 10px;
}

.header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.table-pagination {
  margin-top: 14px;
  justify-content: flex-end;
}

.stats-hint {
  margin-bottom: 12px;
}

.stats-wrapper {
  margin-bottom: 14px;
}

.stats-cards {
  margin-bottom: 10px;
}

.stats-card {
  border-radius: 10px;
}

.stats-label {
  color: #909399;
  font-size: 13px;
  margin-bottom: 6px;
}

.stats-value {
  color: #303133;
  font-size: 24px;
  font-weight: 600;
  line-height: 1;
}

.stats-detail {
  border: 1px solid #ebeef5;
}

.stats-detail-header {
  font-weight: 600;
}
</style>
