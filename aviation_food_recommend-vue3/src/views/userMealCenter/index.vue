<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { getUserMealSelectionListAPI } from '@/api/userMeal'
import type { UserMealSelectionItem } from '@/types/aviation'

const loading = ref(false)
const list = ref<UserMealSelectionItem[]>([])
const queryForm = ref({
  flightNumber: '',
  name: '',
  idNumber: '',
})
const page = ref(1)
const pageSize = ref(10)

const pagedList = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return list.value.slice(start, start + pageSize.value)
})

const loadData = async () => {
  loading.value = true
  const { data: res } = await getUserMealSelectionListAPI({
    flightNumber: queryForm.value.flightNumber?.trim() || undefined,
    name: queryForm.value.name?.trim() || undefined,
    idNumber: queryForm.value.idNumber?.trim() || undefined,
  })
  loading.value = false
  if (res.code !== 0) return
  list.value = res.data || []
}

const reset = async () => {
  queryForm.value = {
    flightNumber: '',
    name: '',
    idNumber: '',
  }
  page.value = 1
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
        <el-form-item>
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button @click="reset">重置</el-button>
        </el-form-item>
      </el-form>

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
        :total="list.length"
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
</style>
