<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  addFlightPassengerAPI,
  deleteFlightPassengerAPI,
  getFlightListAPI,
  getFlightPassengersAPI,
  updateFlightPassengerAPI,
} from '@/api/flight'
import type {
  FlightItem,
  FlightPassengerItem,
  FlightPassengerUpsertPayload,
} from '@/types/aviation'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const passengerLoading = ref(false)
const allFlights = ref<FlightItem[]>([])
const passengers = ref<FlightPassengerItem[]>([])
const queryForm = reactive({
  flightNumber: '',
  departure: '',
  destination: '',
})
const appliedQuery = reactive({
  flightNumber: '',
  departure: '',
  destination: '',
})
const selectedFlight = ref<FlightItem | null>(null)
const passengerDialogVisible = ref(false)
const editingPassengerId = ref<number | null>(null)
const passengerForm = ref({
  name: '',
  idNumber: '',
  phone: '',
  gender: 1,
})
const flightsPage = ref(1)
const flightsPageSize = ref(10)
const passengersPage = ref(1)
const passengersPageSize = ref(10)

const FLIGHT_NUMBER_REGEX = /^[A-Za-z0-9-]+$/
const HAS_ALNUM_REGEX = /[A-Za-z0-9]/
const PHONE_REGEX = /^1\d{10}$/
const ID_NUMBER_REGEX = /^(\d{17}[\dXx])$/

const validatePlace = (value: string, fieldName: '出发地' | '目的地', required = false) => {
  const trimmed = value.trim()
  if (required && !trimmed) {
    ElMessage.warning(`${fieldName}不能为空`)
    return false
  }
  if (trimmed && HAS_ALNUM_REGEX.test(trimmed)) {
    ElMessage.warning(`${fieldName}不能包含字母或数字`)
    return false
  }
  return true
}

const validateQueryForm = () => {
  const flightNumber = queryForm.flightNumber.trim()
  if (flightNumber && !FLIGHT_NUMBER_REGEX.test(flightNumber)) {
    ElMessage.warning('航班号只能包含字母、数字或中划线，不能输入汉字')
    return false
  }
  if (!validatePlace(queryForm.departure, '出发地')) {
    return false
  }
  if (!validatePlace(queryForm.destination, '目的地')) {
    return false
  }
  return true
}

const loadData = async () => {
  loading.value = true
  const { data: res } = await getFlightListAPI()
  loading.value = false
  if (res.code !== 0) return
  allFlights.value = res.data || []
  autoSelectByQuery()
}

const filteredFlights = computed(() => {
  const flightNumber = appliedQuery.flightNumber.trim().toUpperCase()
  const departure = appliedQuery.departure.trim()
  const destination = appliedQuery.destination.trim()
  return allFlights.value.filter((item) => {
    const numberMatched = !flightNumber || (item.flightNumber || '').toUpperCase().includes(flightNumber)
    const departureMatched = !departure || (item.departure || '').includes(departure)
    const destinationMatched = !destination || (item.destination || '').includes(destination)
    return numberMatched && departureMatched && destinationMatched
  })
})

const pagedFlights = computed(() => {
  const start = (flightsPage.value - 1) * flightsPageSize.value
  return filteredFlights.value.slice(start, start + flightsPageSize.value)
})

const pagedPassengers = computed(() => {
  const start = (passengersPage.value - 1) * passengersPageSize.value
  return passengers.value.slice(start, start + passengersPageSize.value)
})

const syncFromRoute = () => {
  const queryFlightNumber = String(route.query.flightNumber || '')
  const queryDeparture = String(route.query.departure || '')
  const queryDestination = String(route.query.destination || '')
  queryForm.flightNumber = queryFlightNumber
  queryForm.departure = queryDeparture
  queryForm.destination = queryDestination
  appliedQuery.flightNumber = queryFlightNumber
  appliedQuery.departure = queryDeparture
  appliedQuery.destination = queryDestination
}

const loadPassengers = async (flightId: number) => {
  passengerLoading.value = true
  const { data: res } = await getFlightPassengersAPI(flightId)
  passengerLoading.value = false
  if (res.code !== 0) return
  passengers.value = res.data || []
}

const selectFlight = (row: FlightItem) => {
  selectedFlight.value = row
  loadPassengers(row.id)
}

const openAddPassengerDialog = () => {
  if (!selectedFlight.value) {
    ElMessage.warning('请先选择航班')
    return
  }
  editingPassengerId.value = null
  passengerForm.value = {
    name: '',
    idNumber: '',
    phone: '',
    gender: 1,
  }
  passengerDialogVisible.value = true
}

const openEditPassengerDialog = (row: FlightPassengerItem) => {
  editingPassengerId.value = row.userId
  passengerForm.value = {
    name: row.name || '',
    idNumber: row.idNumber || '',
    phone: row.phone || '',
    gender: row.gender === '女' ? 0 : 1,
  }
  passengerDialogVisible.value = true
}

const savePassenger = async () => {
  if (!selectedFlight.value) {
    ElMessage.warning('请先选择航班')
    return
  }
  if (!passengerForm.value.name.trim()) {
    ElMessage.warning('请输入客户姓名')
    return
  }
  const idNumber = passengerForm.value.idNumber?.trim()
  if (idNumber && !ID_NUMBER_REGEX.test(idNumber)) {
    ElMessage.warning('身份证号格式不正确')
    return
  }
  const phone = passengerForm.value.phone?.trim()
  if (phone && !PHONE_REGEX.test(phone)) {
    ElMessage.warning('手机号格式不正确')
    return
  }
  const payload: FlightPassengerUpsertPayload = {
    flightId: selectedFlight.value.id,
    name: passengerForm.value.name.trim(),
    idNumber: passengerForm.value.idNumber?.trim() || undefined,
    phone: passengerForm.value.phone?.trim() || undefined,
    gender: passengerForm.value.gender,
  }
  if (editingPassengerId.value) {
    const { data: res } = await updateFlightPassengerAPI({ ...payload, id: editingPassengerId.value })
    if (res.code !== 0) return
    ElMessage.success('客户信息已更新')
  } else {
    const { data: res } = await addFlightPassengerAPI(payload)
    if (res.code !== 0) return
    ElMessage.success('客户新增成功')
  }
  passengerDialogVisible.value = false
  await loadPassengers(selectedFlight.value.id)
}

const removePassenger = (row: FlightPassengerItem) => {
  if (!Number.isInteger(row.userId) || row.userId <= 0) {
    ElMessage.warning('删除失败：客户ID无效')
    return
  }
  ElMessageBox.confirm('确认删除该客户吗？删除后不可恢复。', '提示', {
    type: 'warning',
  })
    .then(async () => {
      const { data: res } = await deleteFlightPassengerAPI(row.userId)
      if (res.code !== 0) return
      ElMessage.success('客户删除成功')
      if (selectedFlight.value) {
        await loadPassengers(selectedFlight.value.id)
      }
    })
    .catch(() => {})
}

const autoSelectByQuery = () => {
  if (!filteredFlights.value.length) {
    selectedFlight.value = null
    passengers.value = []
    return
  }
  const keyword = appliedQuery.flightNumber.trim().toUpperCase()
  if (!keyword || !allFlights.value.length) {
    const first = filteredFlights.value[0]
    if (first) {
      selectFlight(first)
    }
    return
  }
  const exact = allFlights.value.find((item) => (item.flightNumber || '').toUpperCase() === keyword)
  if (exact) {
    selectFlight(exact)
    return
  }
  const first = filteredFlights.value[0]
  if (first) {
    selectFlight(first)
  }
}

const search = () => {
  if (!validateQueryForm()) {
    return
  }
  appliedQuery.flightNumber = queryForm.flightNumber
  appliedQuery.departure = queryForm.departure
  appliedQuery.destination = queryForm.destination
  flightsPage.value = 1
  router.replace({
    path: '/flight-center',
    query: {
      ...(queryForm.flightNumber ? { flightNumber: queryForm.flightNumber } : {}),
      ...(queryForm.departure ? { departure: queryForm.departure } : {}),
      ...(queryForm.destination ? { destination: queryForm.destination } : {}),
    },
  })
  autoSelectByQuery()
}

const reset = () => {
  queryForm.flightNumber = ''
  queryForm.departure = ''
  queryForm.destination = ''
  appliedQuery.flightNumber = ''
  appliedQuery.departure = ''
  appliedQuery.destination = ''
  selectedFlight.value = null
  passengers.value = []
  flightsPage.value = 1
  passengersPage.value = 1
  router.replace({ path: '/flight-center' })
}

watch(
  () => route.query.flightNumber,
  () => {
    syncFromRoute()
    autoSelectByQuery()
  },
)

onMounted(async () => {
  syncFromRoute()
  await loadData()
})
</script>

<template>
  <div class="page" v-loading="loading">
    <el-card>
      <template #header>
        <div class="header-row">
          <span>航班管理中心</span>
          <el-button @click="loadData">刷新</el-button>
        </div>
      </template>

      <el-form inline>
        <el-form-item label="航班号">
          <el-input v-model="queryForm.flightNumber" placeholder="请输入航班号" clearable />
        </el-form-item>
        <el-form-item label="出发地">
          <el-input v-model="queryForm.departure" placeholder="请输入出发地" clearable />
        </el-form-item>
        <el-form-item label="目的地">
          <el-input v-model="queryForm.destination" placeholder="请输入目的地" clearable />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="search">查询</el-button>
          <el-button @click="reset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="pagedFlights" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="flightNumber" label="航班号" min-width="140" />
        <el-table-column prop="departure" label="出发地" min-width="120" />
        <el-table-column prop="destination" label="目的地" min-width="120" />
        <el-table-column prop="durationMinutes" label="时长(分钟)" min-width="120" />
        <el-table-column prop="mealCount" label="供餐次数" min-width="100" />
        <el-table-column label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 1 ? 'success' : 'info'">
              {{ scope.row.status === 1 ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="客户信息" width="120">
          <template #default="scope">
            <el-button type="primary" link @click="selectFlight(scope.row)">查看客户</el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="未查询到符合条件的航班" />
        </template>
      </el-table>
      <el-pagination
        class="table-pagination"
        v-model:current-page="flightsPage"
        v-model:page-size="flightsPageSize"
        :page-sizes="[10, 15, 20]"
        :total="filteredFlights.length"
        layout="total, sizes, prev, pager, next, jumper"
        background
      />
    </el-card>

    <el-card style="margin-top: 14px" v-loading="passengerLoading">
      <template #header>
        <div class="header-row">
          <span>当前航班客户信息</span>
          <div style="display: flex; align-items: center; gap: 12px">
            <span v-if="selectedFlight" style="color: #409eff">
              {{ selectedFlight.flightNumber }}（{{ selectedFlight.departure }} → {{ selectedFlight.destination }}）
            </span>
            <el-button type="primary" @click="openAddPassengerDialog" :disabled="!selectedFlight">新增客户</el-button>
          </div>
        </div>
      </template>

      <el-table :data="pagedPassengers" border stripe>
        <el-table-column prop="userId" label="客户ID" width="90" />
        <el-table-column prop="name" label="姓名" min-width="120" />
        <el-table-column prop="idNumber" label="身份证号" min-width="190" />
        <el-table-column prop="age" label="年龄" width="80" />
        <el-table-column prop="phone" label="手机号" min-width="130" />
        <el-table-column prop="gender" label="性别" width="80" />
        <el-table-column label="偏好完成" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.preferenceCompleted === 1 ? 'success' : 'warning'">
              {{ scope.row.preferenceCompleted === 1 ? '已完成' : '未完成' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="是否选餐" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.mealSelected === '已选餐' ? 'success' : 'warning'">
              {{ scope.row.mealSelected || '未选餐' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="bindStatus" label="绑定状态" width="100" />
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="scope">
            <el-button type="primary" link @click="openEditPassengerDialog(scope.row)">编辑</el-button>
            <el-button type="danger" link @click="removePassenger(scope.row)">删除</el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty :description="selectedFlight ? '当前航班暂无客户' : '请先选择航班查看客户信息'" />
        </template>
      </el-table>
      <el-pagination
        class="table-pagination"
        v-model:current-page="passengersPage"
        v-model:page-size="passengersPageSize"
        :page-sizes="[10, 15, 20]"
        :total="passengers.length"
        layout="total, sizes, prev, pager, next, jumper"
        background
      />
    </el-card>

    <el-dialog v-model="passengerDialogVisible" :title="editingPassengerId ? '编辑客户' : '新增客户'" width="520px">
      <el-form label-width="100px">
        <el-form-item label="姓名" required>
          <el-input v-model="passengerForm.name" maxlength="20" show-word-limit />
        </el-form-item>
        <el-form-item label="身份证号">
          <el-input v-model="passengerForm.idNumber" maxlength="18" />
        </el-form-item>
        <el-form-item label="手机号">
          <el-input v-model="passengerForm.phone" maxlength="11" />
        </el-form-item>
        <el-form-item label="性别">
          <el-radio-group v-model="passengerForm.gender">
            <el-radio :value="1">男</el-radio>
            <el-radio :value="0">女</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="passengerDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="savePassenger">保存</el-button>
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
