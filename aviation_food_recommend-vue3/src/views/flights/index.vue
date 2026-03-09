<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { addFlightAPI, deleteFlightAPI, getFlightListAPI, updateFlightAPI } from '@/api/flight'
import type { FlightItem, FlightUpsertPayload } from '@/types/aviation'

const router = useRouter()

const list = ref<FlightItem[]>([])
const loading = ref(false)
const editDialogVisible = ref(false)
const page = ref(1)
const pageSize = ref(10)

const pagedList = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return list.value.slice(start, start + pageSize.value)
})

const form = reactive({
  flightNumber: '',
  departure: '',
  destination: '',
  departureTime: '',
  arrivalTime: '',
  durationMinutes: 120,
  selectionDeadline: '',
  mealTimes: '["起飞后1小时"]',
})

const editForm = reactive({
  id: 0,
  flightNumber: '',
  departure: '',
  destination: '',
  departureTime: '',
  arrivalTime: '',
  durationMinutes: 120,
  selectionDeadline: '',
  mealCount: 1,
  status: 1,
})

const calcDurationMinutes = (departureTime?: string, arrivalTime?: string) => {
  if (!departureTime || !arrivalTime) return null
  const departure = new Date(departureTime).getTime()
  const arrival = new Date(arrivalTime).getTime()
  if (Number.isNaN(departure) || Number.isNaN(arrival) || arrival <= departure) {
    return null
  }
  return Math.max(30, Math.floor((arrival - departure) / 60000))
}

const validateFlightForm = (source: {
  flightNumber: string
  departure: string
  destination: string
  departureTime: string
  arrivalTime: string
  selectionDeadline: string
}) => {
  if (!source.flightNumber || !source.departure || !source.destination || !source.departureTime || !source.arrivalTime) {
    ElMessage.warning('请完善航班号、出发地、目的地、起飞和到达时间')
    return null
  }
  const duration = calcDurationMinutes(source.departureTime, source.arrivalTime)
  if (duration == null) {
    ElMessage.warning('到达时间必须晚于起飞时间')
    return null
  }
  if (source.selectionDeadline) {
    const deadline = new Date(source.selectionDeadline).getTime()
    const departure = new Date(source.departureTime).getTime()
    if (!Number.isNaN(deadline) && !Number.isNaN(departure) && deadline > departure) {
      ElMessage.warning('预选截止不能晚于起飞时间')
      return null
    }
  }
  return duration
}

const loadData = async () => {
  loading.value = true
  const { data: res } = await getFlightListAPI()
  loading.value = false
  if (res.code !== 0) return
  list.value = res.data || []
}

const addFlight = async () => {
  const duration = validateFlightForm(form)
  if (duration == null) {
    return
  }
  form.durationMinutes = duration
  const payload: FlightUpsertPayload = {
    ...form,
    flightNumber: form.flightNumber.trim().toUpperCase(),
    departure: form.departure.trim(),
    destination: form.destination.trim(),
    durationMinutes: duration,
    mealCount: duration >= 180 ? 2 : 1,
    status: 1,
  }
  const { data: res } = await addFlightAPI(payload)
  if (res.code !== 0) return
  ElMessage.success('新增航班成功')
  form.flightNumber = ''
  form.departure = ''
  form.destination = ''
  form.departureTime = ''
  form.arrivalTime = ''
  form.durationMinutes = 120
  form.selectionDeadline = ''
  loadData()
}

const removeFlight = async (id: number) => {
  ElMessageBox.confirm('确认删除该航班吗？', '提示', {
    type: 'warning',
  })
    .then(async () => {
      const { data: res } = await deleteFlightAPI(id)
      if (res.code !== 0) return
      ElMessage.success('删除成功')
      loadData()
    })
    .catch(() => {})
}

const openEditDialog = (row: FlightItem) => {
  editForm.id = row.id
  editForm.flightNumber = row.flightNumber || ''
  editForm.departure = row.departure || ''
  editForm.destination = row.destination || ''
  editForm.departureTime = row.departureTime || ''
  editForm.arrivalTime = row.arrivalTime || ''
  editForm.durationMinutes = row.durationMinutes || 120
  editForm.selectionDeadline = row.selectionDeadline || ''
  editForm.mealCount = row.mealCount || 1
  editForm.status = row.status ?? 1
  editDialogVisible.value = true
}

const saveEdit = async () => {
  const duration = validateFlightForm(editForm)
  if (duration == null) {
    return
  }
  editForm.durationMinutes = duration
  const payload: FlightUpsertPayload = {
    ...editForm,
    flightNumber: editForm.flightNumber.trim().toUpperCase(),
    departure: editForm.departure.trim(),
    destination: editForm.destination.trim(),
    durationMinutes: duration,
    mealCount: duration >= 180 ? 2 : 1,
  }
  const { data: res } = await updateFlightAPI(payload)
  if (res.code !== 0) return
  ElMessage.success('修改成功')
  editDialogVisible.value = false
  loadData()
}

const goFlightCenter = (flightNumber: string) => {
  router.push({
    path: '/flight-center',
    query: { flightNumber },
  })
}

onMounted(loadData)
</script>

<template>
  <div class="page">
    <el-card>
      <template #header>
        <div class="header-row">
          <span>航班信息管理</span>
          <el-button @click="loadData">刷新</el-button>
        </div>
      </template>
      <el-form inline>
        <el-form-item label="航班号"><el-input v-model="form.flightNumber" /></el-form-item>
        <el-form-item label="出发地"><el-input v-model="form.departure" /></el-form-item>
        <el-form-item label="目的地"><el-input v-model="form.destination" /></el-form-item>
        <el-form-item label="起飞时间">
          <el-date-picker
            v-model="form.departureTime"
            type="datetime"
            value-format="YYYY-MM-DD HH:mm:ss"
            format="YYYY-MM-DD HH:mm:ss"
            placeholder="请选择起飞时间"
          />
        </el-form-item>
        <el-form-item label="到达时间">
          <el-date-picker
            v-model="form.arrivalTime"
            type="datetime"
            value-format="YYYY-MM-DD HH:mm:ss"
            format="YYYY-MM-DD HH:mm:ss"
            placeholder="请选择到达时间"
          />
        </el-form-item>
        <el-form-item label="飞行时长(分钟)"><el-input-number v-model="form.durationMinutes" :min="30" /></el-form-item>
        <el-form-item label="预选截止">
          <el-date-picker
            v-model="form.selectionDeadline"
            type="datetime"
            value-format="YYYY-MM-DD HH:mm:ss"
            format="YYYY-MM-DD HH:mm:ss"
            placeholder="请选择截止时间"
          />
        </el-form-item>
        <el-form-item><el-button type="primary" @click="addFlight">新增航班</el-button></el-form-item>
      </el-form>

      <el-table :data="pagedList" border v-loading="loading">
        <el-table-column prop="id" label="ID" width="70" />
        <el-table-column label="航班号">
          <template #default="scope">
            <el-button type="primary" link @click="goFlightCenter(scope.row.flightNumber)">
              {{ scope.row.flightNumber }}
            </el-button>
          </template>
        </el-table-column>
        <el-table-column prop="departure" label="出发地" />
        <el-table-column prop="destination" label="目的地" />
        <el-table-column prop="departureTime" label="起飞时间" min-width="170" />
        <el-table-column prop="arrivalTime" label="到达时间" min-width="170" />
        <el-table-column prop="durationMinutes" label="时长(分钟)" />
        <el-table-column prop="selectionDeadline" label="预选截止时间" min-width="180" />
        <el-table-column prop="mealCount" label="供餐次数" />
        <el-table-column label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 1 ? 'success' : 'info'">
              {{ scope.row.status === 1 ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120">
          <template #default="scope">
            <el-button type="primary" link @click="openEditDialog(scope.row)">编辑</el-button>
            <el-button type="danger" link @click="removeFlight(scope.row.id)">删除</el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="暂无航班数据" />
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

    <el-dialog v-model="editDialogVisible" title="编辑航班" width="520px">
      <el-form label-width="100px">
        <el-form-item label="航班号"><el-input v-model="editForm.flightNumber" /></el-form-item>
        <el-form-item label="出发地"><el-input v-model="editForm.departure" /></el-form-item>
        <el-form-item label="目的地"><el-input v-model="editForm.destination" /></el-form-item>
        <el-form-item label="起飞时间">
          <el-date-picker
            v-model="editForm.departureTime"
            type="datetime"
            value-format="YYYY-MM-DD HH:mm:ss"
            format="YYYY-MM-DD HH:mm:ss"
            placeholder="请选择起飞时间"
          />
        </el-form-item>
        <el-form-item label="到达时间">
          <el-date-picker
            v-model="editForm.arrivalTime"
            type="datetime"
            value-format="YYYY-MM-DD HH:mm:ss"
            format="YYYY-MM-DD HH:mm:ss"
            placeholder="请选择到达时间"
          />
        </el-form-item>
        <el-form-item label="飞行时长">
          <el-input-number v-model="editForm.durationMinutes" :min="30" />
        </el-form-item>
        <el-form-item label="预选截止">
          <el-date-picker
            v-model="editForm.selectionDeadline"
            type="datetime"
            value-format="YYYY-MM-DD HH:mm:ss"
            format="YYYY-MM-DD HH:mm:ss"
            placeholder="请选择截止时间"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveEdit">保存</el-button>
      </template>
    </el-dialog>
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
