<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getRecommendationDashboardAPI, getRecommendationExceptionAPI } from '@/api/recommendation'
import {
  addAnnouncementAPI,
  deleteAnnouncementAPI,
  getAnnouncementListAPI,
  getFlightListAPI,
  updateAnnouncementAPI,
} from '@/api/flight'
import type { AnnouncementItem, FlightItem } from '@/types/aviation'

const loading = ref(false)
const announcementList = ref<AnnouncementItem[]>([])
const flightList = ref<FlightItem[]>([])
const editDialogVisible = ref(false)
const coreAlgorithm = ref({
  name: 'fused-pmfup-prmidm-ammbc-v1',
  summary: '融合 PMFUP / PRMIDM / AMMBC 的单一核心推荐算法（论文主算法）',
})
const dashboard = ref({
  recommendCount: 0,
  preferenceUserCount: 0,
  selectionCount: 0,
  avgRating: 0,
})
const exceptionUsers = ref<Array<{
  userId: number
  userName: string
  idNumber?: string
  currentFlightId?: number
  preferenceCompleted: number
  exceptionType: string
}>>([])
const annPage = ref(1)
const annPageSize = ref(10)
const exPage = ref(1)
const exPageSize = ref(10)

const pagedAnnouncements = () => {
  const start = (annPage.value - 1) * annPageSize.value
  return announcementList.value.slice(start, start + annPageSize.value)
}

const pagedExceptionUsers = () => {
  const start = (exPage.value - 1) * exPageSize.value
  return exceptionUsers.value.slice(start, start + exPageSize.value)
}

const form = reactive({
  id: 0,
  flightId: undefined as number | undefined,
  title: '',
  content: '',
  status: 1,
})

const query = reactive({
  flightId: undefined as number | undefined,
})

const loadData = async () => {
  loading.value = true
  const [annRes, dashboardRes, exceptionRes] = await Promise.all([
    getAnnouncementListAPI(query.flightId),
    getRecommendationDashboardAPI(),
    getRecommendationExceptionAPI(),
  ])
  loading.value = false

  if (annRes.data.code === 0) {
    announcementList.value = annRes.data.data || []
  }
  if (dashboardRes.data.code === 0 && dashboardRes.data.data) {
    dashboard.value = {
      recommendCount: Number(dashboardRes.data.data.recommendCount || 0),
      preferenceUserCount: Number(dashboardRes.data.data.preferenceUserCount || 0),
      selectionCount: Number(dashboardRes.data.data.selectionCount || 0),
      avgRating: Number(dashboardRes.data.data.avgRating || 0),
    }
  }
  if (exceptionRes.data.code === 0) {
    exceptionUsers.value = exceptionRes.data.data || []
  }
}

const loadFlights = async () => {
  const { data: res } = await getFlightListAPI()
  if (res.code !== 0) return
  flightList.value = res.data || []
}

const resetForm = () => {
  form.id = 0
  form.flightId = undefined
  form.title = ''
  form.content = ''
  form.status = 1
}

const submitAnnouncement = async () => {
  if (!form.title || !form.content) {
    ElMessage.warning('请填写公告标题和内容')
    return
  }
  const payload = {
    flightId: form.flightId,
    title: form.title,
    content: form.content,
    status: form.status,
  }

  const { data: res } = form.id
    ? await updateAnnouncementAPI({ ...payload, id: form.id })
    : await addAnnouncementAPI(payload)

  if (res.code !== 0) return
  ElMessage.success(form.id ? '公告修改成功' : '公告新增成功')
  editDialogVisible.value = false
  resetForm()
  loadData()
}

const openCreateDialog = () => {
  resetForm()
  editDialogVisible.value = true
}

const openEditDialog = (row: AnnouncementItem) => {
  form.id = row.id
  form.flightId = row.flightId
  form.title = row.title || ''
  form.content = row.content || ''
  form.status = row.status ?? 1
  editDialogVisible.value = true
}

const removeAnnouncement = (id: number) => {
  ElMessageBox.confirm('确认删除该公告吗？', '提示', {
    type: 'warning',
  })
    .then(async () => {
      const { data: res } = await deleteAnnouncementAPI(id)
      if (res.code !== 0) return
      ElMessage.success('删除成功')
      loadData()
    })
    .catch(() => {})
}

onMounted(async () => {
  await loadFlights()
  await loadData()
})
</script>

<template>
  <div v-loading="loading">
    <el-card>
      <template #header>
        <div class="header-row">
          <span>公告管理中心</span>
          <div class="header-actions">
            <el-select v-model="query.flightId" placeholder="按航班筛选" clearable style="width: 180px">
              <el-option v-for="item in flightList" :key="item.id" :label="item.flightNumber" :value="item.id" />
            </el-select>
            <el-button @click="loadData">查询</el-button>
            <el-button type="primary" @click="openCreateDialog">新增公告</el-button>
          </div>
        </div>
      </template>

      <el-table :data="pagedAnnouncements()" border stripe>
        <el-table-column prop="id" label="ID" width="70" />
        <el-table-column label="航班" min-width="120">
          <template #default="scope">
            {{ flightList.find((item) => item.id === scope.row.flightId)?.flightNumber || '全局公告' }}
          </template>
        </el-table-column>
        <el-table-column prop="title" label="标题" min-width="180" />
        <el-table-column prop="content" label="内容" min-width="320" show-overflow-tooltip />
        <el-table-column label="状态" width="90">
          <template #default="scope">
            <el-tag :type="scope.row.status === 1 ? 'success' : 'info'">
              {{ scope.row.status === 1 ? '已发布' : '草稿' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140">
          <template #default="scope">
            <el-button type="primary" link @click="openEditDialog(scope.row)">编辑</el-button>
            <el-button type="danger" link @click="removeAnnouncement(scope.row.id)">删除</el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="暂无公告" />
        </template>
      </el-table>
      <el-pagination
        class="table-pagination"
        v-model:current-page="annPage"
        v-model:page-size="annPageSize"
        :page-sizes="[10, 15, 20]"
        :total="announcementList.length"
        layout="total, sizes, prev, pager, next, jumper"
        background
      />
    </el-card>

    <el-card style="margin-top: 14px">
      <template #header>
        <div class="header-row">
          <span>论文核心算法监控</span>
        </div>
      </template>
      <div class="algo-panel">
        <div class="algo-name">{{ coreAlgorithm.name }}</div>
        <div class="algo-summary">{{ coreAlgorithm.summary }}</div>
        <div class="algo-grid">
          <div class="metric-item">
            <div class="metric-label">累计推荐次数</div>
            <div class="metric-value">{{ dashboard.recommendCount }}</div>
          </div>
          <div class="metric-item">
            <div class="metric-label">画像用户数</div>
            <div class="metric-value">{{ dashboard.preferenceUserCount }}</div>
          </div>
          <div class="metric-item">
            <div class="metric-label">预选完成次数</div>
            <div class="metric-value">{{ dashboard.selectionCount }}</div>
          </div>
          <div class="metric-item">
            <div class="metric-label">平均满意度</div>
            <div class="metric-value">{{ dashboard.avgRating.toFixed(2) }}</div>
          </div>
        </div>
      </div>
    </el-card>

    <el-card style="margin-top: 14px">
      <template #header>
        <div class="header-row">
          <span>异常治理名单</span>
        </div>
      </template>
      <el-table :data="pagedExceptionUsers()" border stripe>
        <el-table-column prop="userId" label="用户ID" width="90" />
        <el-table-column prop="userName" label="姓名" min-width="120" />
        <el-table-column prop="idNumber" label="身份证号" min-width="190" />
        <el-table-column prop="currentFlightId" label="当前航班ID" width="110" />
        <el-table-column label="偏好状态" width="110">
          <template #default="scope">
            <el-tag :type="scope.row.preferenceCompleted === 1 ? 'success' : 'warning'">
              {{ scope.row.preferenceCompleted === 1 ? '已完成' : '未完成' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="exceptionType" label="异常类型" min-width="140" />
        <template #empty>
          <el-empty description="暂无异常用户" />
        </template>
      </el-table>
      <el-pagination
        class="table-pagination"
        v-model:current-page="exPage"
        v-model:page-size="exPageSize"
        :page-sizes="[10, 15, 20]"
        :total="exceptionUsers.length"
        layout="total, sizes, prev, pager, next, jumper"
        background
      />
    </el-card>

    <el-dialog v-model="editDialogVisible" :title="form.id ? '编辑公告' : '新增公告'" width="560px">
      <el-form label-width="90px">
        <el-form-item label="关联航班">
          <el-select v-model="form.flightId" clearable placeholder="不选则为全局公告" style="width: 100%">
            <el-option v-for="item in flightList" :key="item.id" :label="item.flightNumber" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="公告标题">
          <el-input v-model="form.title" maxlength="100" show-word-limit />
        </el-form-item>
        <el-form-item label="公告内容">
          <el-input v-model="form.content" type="textarea" :rows="4" maxlength="500" show-word-limit />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitAnnouncement">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.table-pagination {
  margin-top: 14px;
  justify-content: flex-end;
}

.algo-panel {
  border: 1px solid #e4ebf5;
  border-radius: 10px;
  padding: 16px;
  background: linear-gradient(145deg, #f9fcff 0%, #eef6ff 100%);
}

.algo-name {
  font-size: 18px;
  font-weight: 700;
  color: #1f4061;
}

.algo-summary {
  margin-top: 8px;
  color: #4b6986;
}

.algo-grid {
  margin-top: 14px;
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
}

.metric-item {
  border: 1px solid #dce7f3;
  border-radius: 8px;
  background: #fff;
  padding: 10px;
}

.metric-label {
  color: #6c839b;
  font-size: 12px;
}

.metric-value {
  margin-top: 4px;
  color: #18486e;
  font-size: 22px;
  font-weight: 700;
}

@media (max-width: 1200px) {
  .algo-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
