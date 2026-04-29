<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  addFlightPassengerAPI,
  deleteFlightPassengerAPI,
  getFlightListAPI,
  searchExistingFlightPassengersAPI,
  searchFlightPassengersAPI,
  updateFlightPassengerAPI,
} from '@/api/flight'
import type {
  ExistingPassengerCandidateItem,
  FlightItem,
  FlightPassengerItem,
  FlightPassengerUpsertPayload,
} from '@/types/aviation'

const loading = ref(false)
const passengerLoading = ref(false)
const allFlights = ref<FlightItem[]>([])
const passengers = ref<FlightPassengerItem[]>([])
const page = ref(1)
const pageSize = ref(10)

const queryForm = ref({
  flightNumber: '',
  name: '',
  idNumber: '',
})

const passengerDialogVisible = ref(false)
const editingPassengerId = ref<number | null>(null)
const passengerForm = ref({
  sourceType: 1,
  existingUserId: undefined as number | undefined,
  existingKeyword: '',
  name: '',
  idNumber: '',
  phone: '',
  gender: 1,
  cabinType: 3,
  selectedFlightId: undefined as number | undefined,
})
const existingCandidates = ref<ExistingPassengerCandidateItem[]>([])
const existingLoading = ref(false)

const PHONE_REGEX = /^1\d{10}$/
const ID_NUMBER_REGEX = /^(\d{17}[\dXx])$/

const pagedPassengers = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return passengers.value.slice(start, start + pageSize.value)
})

const isValidIdNumber = (idNumber: string) => {
  const normalized = idNumber.trim().toUpperCase()
  if (!ID_NUMBER_REGEX.test(normalized)) {
    return false
  }
  const birthdayText = normalized.slice(6, 14)
  const year = Number(birthdayText.slice(0, 4))
  const month = Number(birthdayText.slice(4, 6))
  const day = Number(birthdayText.slice(6, 8))
  if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
    return false
  }
  const birthdayDate = new Date(year, month - 1, day)
  if (
    birthdayDate.getFullYear() !== year
    || birthdayDate.getMonth() !== month - 1
    || birthdayDate.getDate() !== day
  ) {
    return false
  }
  const today = new Date()
  const minYear = today.getFullYear() - 130
  if (year < minYear || birthdayDate > today) {
    return false
  }
  return true
}

const loadData = async () => {
  passengerLoading.value = true
  const fn = queryForm.value.flightNumber.trim()
  const n = queryForm.value.name.trim()
  const id = queryForm.value.idNumber.trim()
  const hasFilter = fn || n || id
  if (!hasFilter) {
    passengers.value = []
    passengerLoading.value = false
    return
  }
  const { data: res } = await searchFlightPassengersAPI({
    flightNumber: fn || undefined,
    name: n || undefined,
    idNumber: id || undefined,
  })
  passengerLoading.value = false
  if (res.code === 0) {
    passengers.value = res.data || []
  }
}

const loadFlights = async () => {
  loading.value = true
  const { data: res } = await getFlightListAPI()
  loading.value = false
  if (res.code !== 0) {
    return
  }
  allFlights.value = res.data || []
}

const refreshData = async () => {
  await loadFlights()
  await loadData()
}

const search = async () => {
  page.value = 1
  await loadData()
}

const reset = () => {
  queryForm.value = {
    flightNumber: '',
    name: '',
    idNumber: '',
  }
  page.value = 1
  passengers.value = []
}

const openAddPassengerDialog = () => {
  editingPassengerId.value = null
  passengerForm.value = {
    sourceType: 1,
    existingUserId: undefined,
    existingKeyword: '',
    name: '',
    idNumber: '',
    phone: '',
    gender: 1,
    cabinType: 3,
    selectedFlightId: allFlights.value.length === 1 ? allFlights.value[0].id : undefined,
  }
  existingCandidates.value = []
  passengerDialogVisible.value = true
}

const openEditPassengerDialog = (row: FlightPassengerItem) => {
  editingPassengerId.value = row.userId
  passengerForm.value = {
    sourceType: 1,
    existingUserId: undefined,
    existingKeyword: '',
    name: row.name || '',
    idNumber: row.idNumber || '',
    phone: row.phone || '',
    gender: row.gender === '女' ? 0 : 1,
    cabinType: row.cabinType || 3,
    selectedFlightId: row.flightId,
  }
  passengerDialogVisible.value = true
}

const searchExistingPassengers = async () => {
  const keyword = passengerForm.value.existingKeyword.trim()
  if (!keyword) {
    ElMessage.warning('请输入老用户搜索关键词（姓名/身份证/手机号）')
    return
  }
  existingLoading.value = true
  const { data: res } = await searchExistingFlightPassengersAPI({ keyword, limit: 20 })
  existingLoading.value = false
  if (res.code !== 0) {
    return
  }
  existingCandidates.value = res.data || []
  if (!existingCandidates.value.length) {
    ElMessage.warning('未搜索到匹配老用户，请尝试其他关键词')
  }
}

const handleSourceTypeChange = () => {
  if (passengerForm.value.sourceType === 2) {
    passengerForm.value.name = ''
    passengerForm.value.idNumber = ''
    passengerForm.value.phone = ''
    return
  }
  passengerForm.value.existingUserId = undefined
}

const savePassenger = async () => {
  if (!passengerForm.value.selectedFlightId) {
    ElMessage.warning('请选择航班')
    return
  }
  if (!passengerForm.value.name.trim()) {
    if (passengerForm.value.sourceType === 1) {
      ElMessage.warning('请输入客户姓名')
      return
    }
  }

  if (passengerForm.value.sourceType === 2 && !passengerForm.value.existingUserId) {
    ElMessage.warning('请选择要绑定的老用户')
    return
  }

  const idNumber = passengerForm.value.idNumber?.trim()
  if (passengerForm.value.sourceType === 1 && idNumber && !isValidIdNumber(idNumber)) {
    ElMessage.warning('身份证号格式不正确')
    return
  }
  const phone = passengerForm.value.phone?.trim()
  if (passengerForm.value.sourceType === 1 && phone && !PHONE_REGEX.test(phone)) {
    ElMessage.warning('手机号格式不正确')
    return
  }

  const payload: FlightPassengerUpsertPayload = {
    flightId: passengerForm.value.selectedFlightId,
    sourceType: passengerForm.value.sourceType,
    existingUserId: passengerForm.value.sourceType === 2 ? passengerForm.value.existingUserId : undefined,
    name: passengerForm.value.sourceType === 1 ? passengerForm.value.name.trim() : '',
    idNumber: passengerForm.value.sourceType === 1 && idNumber ? idNumber.toUpperCase() : undefined,
    phone: passengerForm.value.sourceType === 1 ? phone || undefined : undefined,
    gender: passengerForm.value.gender,
    cabinType: passengerForm.value.cabinType,
  }

  if (editingPassengerId.value) {
    const { data: res } = await updateFlightPassengerAPI({ ...payload, id: editingPassengerId.value })
    if (res.code !== 0) {
      return
    }
    ElMessage.success('客户信息已更新')
  } else {
    const { data: res } = await addFlightPassengerAPI(payload)
    if (res.code !== 0) {
      return
    }
    ElMessage.success(passengerForm.value.sourceType === 2 ? '老客户绑定成功' : '客户新增成功')
  }

  passengerDialogVisible.value = false
  await loadData()
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
      if (res.code !== 0) {
        return
      }
      ElMessage.success('客户删除成功')
      await loadData()
    })
    .catch(() => {})
}

onMounted(async () => {
  await loadFlights()
})
</script>

<template>
  <div class="page" v-loading="loading">
    <el-card>
      <template #header>
        <div class="header-row">
          <span>用户管理中心</span>
          <el-button @click="refreshData">刷新</el-button>
        </div>
      </template>

      <el-form inline>
        <el-form-item label="航班号">
          <el-input v-model="queryForm.flightNumber" placeholder="请输入航班号" clearable style="width: 160px" />
        </el-form-item>
        <el-form-item label="姓名">
          <el-input v-model="queryForm.name" placeholder="请输入客户姓名" clearable />
        </el-form-item>
        <el-form-item label="身份证号">
          <el-input v-model="queryForm.idNumber" placeholder="请输入身份证号" clearable />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="search">查询</el-button>
          <el-button @click="reset">重置</el-button>
          <el-button type="success" @click="openAddPassengerDialog">新增客户</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="pagedPassengers" border stripe v-loading="passengerLoading">
        <el-table-column prop="userId" label="客户ID" width="90" />
        <el-table-column prop="flightNumber" label="航班号" width="120">
          <template #default="scope">
            {{ scope.row.flightNumber || '-' }}
          </template>
        </el-table-column>
        <el-table-column label="航线" min-width="160">
          <template #default="scope">
            <template v-if="scope.row.departure && scope.row.destination">
              {{ scope.row.departure }} → {{ scope.row.destination }}
            </template>
            <template v-else>-</template>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="姓名" min-width="110" />
        <el-table-column prop="idNumber" label="身份证号" min-width="180" />
        <el-table-column prop="age" label="年龄" width="80" />
        <el-table-column prop="phone" label="手机号" min-width="130" />
        <el-table-column prop="gender" label="性别" width="80" />
        <el-table-column label="舱型" width="110">
          <template #default="scope">
            {{ scope.row.cabinTypeLabel || (scope.row.cabinType === 1 ? '头等舱' : scope.row.cabinType === 2 ? '商务舱' : '经济舱') }}
          </template>
        </el-table-column>
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
          <el-empty description="暂无符合条件的客户，请输入航班号、姓名或身份证号进行查询" />
        </template>
      </el-table>

      <el-pagination
        class="table-pagination"
        v-model:current-page="page"
        v-model:page-size="pageSize"
        :page-sizes="[10, 15, 20]"
        :total="passengers.length"
        layout="total, sizes, prev, pager, next, jumper"
        background
      />
    </el-card>

    <el-dialog v-model="passengerDialogVisible" :title="editingPassengerId ? '编辑客户' : '新增客户'" width="520px">
      <el-form label-width="100px">
        <el-form-item label="绑定航班" required>
          <el-select
            v-model="passengerForm.selectedFlightId"
            placeholder="请选择航班"
            filterable
            style="width: 100%"
          >
            <el-option
              v-for="flight in allFlights"
              :key="flight.id"
              :label="`${flight.flightNumber}（${flight.departure}→${flight.destination}）`"
              :value="flight.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="客户类型" required>
          <el-radio-group v-model="passengerForm.sourceType" :disabled="!!editingPassengerId" @change="handleSourceTypeChange">
            <el-radio :value="1">新用户录入</el-radio>
            <el-radio :value="2">老用户搜索选择</el-radio>
          </el-radio-group>
        </el-form-item>
        <template v-if="passengerForm.sourceType === 1 || editingPassengerId">
          <el-form-item label="姓名" required>
            <el-input v-model="passengerForm.name" maxlength="20" show-word-limit />
          </el-form-item>
          <el-form-item label="身份证号">
            <el-input v-model="passengerForm.idNumber" maxlength="18" />
          </el-form-item>
          <el-form-item label="手机号">
            <el-input v-model="passengerForm.phone" maxlength="11" />
          </el-form-item>
        </template>
        <template v-else>
          <el-form-item label="老用户搜索" required>
            <el-input v-model="passengerForm.existingKeyword" placeholder="输入姓名/身份证/手机号后点击搜索">
              <template #append>
                <el-button @click="searchExistingPassengers" :loading="existingLoading">搜索</el-button>
              </template>
            </el-input>
          </el-form-item>
          <el-form-item label="选择客户" required>
            <el-select
              v-model="passengerForm.existingUserId"
              placeholder="请选择老用户"
              style="width: 100%"
              filterable
            >
              <el-option
                v-for="item in existingCandidates"
                :key="item.userId"
                :value="item.userId"
                :label="`${item.name || '-'} / ${item.idNumber || '无证件'} / ${item.phone || '无手机号'}`"
              />
            </el-select>
          </el-form-item>
        </template>
        <el-form-item label="性别">
          <el-radio-group v-model="passengerForm.gender">
            <el-radio :value="1">男</el-radio>
            <el-radio :value="0">女</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="舱型" required>
          <el-select v-model="passengerForm.cabinType" style="width: 100%">
            <el-option :value="1" label="头等舱" />
            <el-option :value="2" label="商务舱" />
            <el-option :value="3" label="经济舱" />
          </el-select>
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

.flight-hint {
  margin-bottom: 12px;
  color: #409eff;
  font-size: 13px;
}

.table-pagination {
  margin-top: 14px;
  justify-content: flex-end;
}
</style>
