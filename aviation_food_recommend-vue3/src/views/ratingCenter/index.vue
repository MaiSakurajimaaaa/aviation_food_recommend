<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  deleteRatingTaskAPI,
  expireRatingTaskAPI,
  getRatingCenterDashboardAPI,
  getRatingCenterListAPI,
  reopenRatingTaskAPI,
} from '@/api/recommendation'
import type { RatingCenterDashboard, RatingCenterTaskItem } from '@/types/aviation'

const loading = ref(false)
const tasks = ref<RatingCenterTaskItem[]>([])
const page = ref(1)
const pageSize = ref(10)

const dashboard = ref<RatingCenterDashboard>({
  totalCount: 0,
  pendingCount: 0,
  deferredCount: 0,
  submittedCount: 0,
  expiredCount: 0,
  avgScore: 0,
  submitRate: 0,
})

const query = reactive({
  status: '',
  flightNumber: '',
  userKeyword: '',
})

const statusOptions = [
  { label: '全部状态', value: '' },
  { label: '待评分', value: 'PENDING' },
  { label: '已延期', value: 'DEFERRED' },
  { label: '已提交', value: 'SUBMITTED' },
  { label: '已过期', value: 'EXPIRED' },
]

const statusTagType = (status?: string) => {
  if (status === 'PENDING') return 'warning'
  if (status === 'DEFERRED') return 'info'
  if (status === 'SUBMITTED') return 'success'
  if (status === 'EXPIRED') return 'danger'
  return 'info'
}

const statusText = (status?: string) => {
  if (status === 'PENDING') return '待评分'
  if (status === 'DEFERRED') return '已延期'
  if (status === 'SUBMITTED') return '已提交'
  if (status === 'EXPIRED') return '已过期'
  return '未知'
}

const pagedTasks = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return tasks.value.slice(start, start + pageSize.value)
})

const loadDashboard = async () => {
  const { data: res } = await getRatingCenterDashboardAPI()
  if (res.code !== 0 || !res.data) return
  dashboard.value = {
    totalCount: Number(res.data.totalCount || 0),
    pendingCount: Number(res.data.pendingCount || 0),
    deferredCount: Number(res.data.deferredCount || 0),
    submittedCount: Number(res.data.submittedCount || 0),
    expiredCount: Number(res.data.expiredCount || 0),
    avgScore: Number(res.data.avgScore || 0),
    submitRate: Number(res.data.submitRate || 0),
  }
}

const loadTasks = async () => {
  const { data: res } = await getRatingCenterListAPI({
    status: query.status || undefined,
    flightNumber: query.flightNumber?.trim() || undefined,
    userKeyword: query.userKeyword?.trim() || undefined,
  })
  if (res.code !== 0) return
  tasks.value = res.data || []
  if ((page.value - 1) * pageSize.value >= tasks.value.length) {
    page.value = 1
  }
}

const loadData = async () => {
  loading.value = true
  try {
    await Promise.all([loadDashboard(), loadTasks()])
  } finally {
    loading.value = false
  }
}

const resetQuery = () => {
  query.status = ''
  query.flightNumber = ''
  query.userKeyword = ''
  page.value = 1
  void loadData()
}

const reopenTask = (row: RatingCenterTaskItem) => {
  ElMessageBox.confirm('确认重新打开该评分任务吗？系统将允许乘客重新评分。', '提示', {
    type: 'warning',
  })
    .then(async () => {
      const { data: res } = await reopenRatingTaskAPI(row.id)
      if (res.code !== 0) return
      ElMessage.success('已重开评分任务')
      await loadData()
    })
    .catch(() => {})
}

const expireTask = (row: RatingCenterTaskItem) => {
  ElMessageBox.confirm('确认将该评分任务标记为过期吗？', '提示', {
    type: 'warning',
  })
    .then(async () => {
      const { data: res } = await expireRatingTaskAPI(row.id)
      if (res.code !== 0) return
      ElMessage.success('已标记为过期')
      await loadData()
    })
    .catch(() => {})
}

const removeTask = (row: RatingCenterTaskItem) => {
  ElMessageBox.confirm('确认删除该评分任务吗？此操作不可恢复。', '提示', {
    type: 'warning',
  })
    .then(async () => {
      const { data: res } = await deleteRatingTaskAPI(row.id)
      if (res.code !== 0) return
      ElMessage.success('删除成功')
      await loadData()
    })
    .catch(() => {})
}

onMounted(loadData)
</script>

<template>
  <div v-loading="loading" class="page">
    <div class="kpi-grid">
      <el-card><div class="kpi-title">评分任务总数</div><div class="kpi-value">{{ dashboard.totalCount }}</div></el-card>
      <el-card><div class="kpi-title">待评分</div><div class="kpi-value warn">{{ dashboard.pendingCount }}</div></el-card>
      <el-card><div class="kpi-title">已延期</div><div class="kpi-value">{{ dashboard.deferredCount }}</div></el-card>
      <el-card><div class="kpi-title">已提交</div><div class="kpi-value success">{{ dashboard.submittedCount }}</div></el-card>
      <el-card><div class="kpi-title">提交率</div><div class="kpi-value">{{ dashboard.submitRate.toFixed(2) }}%</div></el-card>
      <el-card><div class="kpi-title">平均评分</div><div class="kpi-value">{{ dashboard.avgScore.toFixed(2) }}</div></el-card>
    </div>

    <el-card style="margin-top: 14px">
      <template #header>
        <div class="header-row">
          <span>评分管理中心</span>
          <el-button @click="loadData">刷新</el-button>
        </div>
      </template>

      <el-form inline>
        <el-form-item label="状态">
          <el-select v-model="query.status" style="width: 140px">
            <el-option v-for="item in statusOptions" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="航班号">
          <el-input v-model="query.flightNumber" placeholder="支持模糊匹配" clearable style="width: 160px" />
        </el-form-item>
        <el-form-item label="用户关键词">
          <el-input v-model="query.userKeyword" placeholder="姓名/身份证/用户ID" clearable style="width: 180px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="pagedTasks" border stripe>
        <el-table-column prop="id" label="任务ID" width="90" />
        <el-table-column label="用户" min-width="170">
          <template #default="scope">
            {{ scope.row.userName }}（#{{ scope.row.userId }}）
          </template>
        </el-table-column>
        <el-table-column prop="flightNumber" label="航班号" width="120" />
        <el-table-column label="航线" min-width="170">
          <template #default="scope">
            {{ scope.row.departure || '-' }} -> {{ scope.row.destination || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="arrivalTime" label="到达时间" min-width="165" />
        <el-table-column label="状态" width="100">
          <template #default="scope">
            <el-tag :type="statusTagType(scope.row.ratingStatus)">{{ statusText(scope.row.ratingStatus) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="评分" width="80">
          <template #default="scope">
            {{ scope.row.ratingScore || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="deferCount" label="延期次数" width="100" />
        <el-table-column prop="nextRemindAt" label="下次提醒" min-width="165" />
        <el-table-column prop="submittedAt" label="提交时间" min-width="165" />
        <el-table-column prop="updateTime" label="更新时间" min-width="165" />
        <el-table-column label="操作" width="230" fixed="right">
          <template #default="scope">
            <el-button type="primary" link @click="reopenTask(scope.row)">重开</el-button>
            <el-button type="warning" link @click="expireTask(scope.row)">过期</el-button>
            <el-button type="danger" link @click="removeTask(scope.row)">删除</el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="暂无评分任务" />
        </template>
      </el-table>
      <el-pagination
        class="table-pagination"
        v-model:current-page="page"
        v-model:page-size="pageSize"
        :page-sizes="[10, 15, 20]"
        :total="tasks.length"
        layout="total, sizes, prev, pager, next, jumper"
        background
      />
    </el-card>
  </div>
</template>

<style scoped>
.page {
  padding: 2px 0;
}

.kpi-grid {
  display: grid;
  grid-template-columns: repeat(6, minmax(0, 1fr));
  gap: 12px;
}

.kpi-title {
  color: #7a869a;
  font-size: 13px;
}

.kpi-value {
  margin-top: 8px;
  font-size: 22px;
  font-weight: 700;
  color: #1f2d3d;
}

.kpi-value.warn {
  color: #d48806;
}

.kpi-value.success {
  color: #389e0d;
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

@media (max-width: 1500px) {
  .kpi-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (max-width: 900px) {
  .kpi-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
