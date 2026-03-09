<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getFlightListAPI, getFlightMealsAPI, addFlightMealAPI, updateFlightMealAPI, deleteFlightMealAPI } from '@/api/flight'
import { getDishPageListAPI } from '@/api/dish'
import type { FlightItem, FlightMealBindingItem, FlightMealBindingUpsertPayload } from '@/types/aviation'

const loading = ref(false)
const mealLoading = ref(false)
const allFlights = ref<FlightItem[]>([])
const mealBindings = ref<FlightMealBindingItem[]>([])
const dishOptions = ref<Array<{ id: number; name: string; status: number }>>([])
const flightNumberQuery = ref('')
const selectedFlight = ref<FlightItem | null>(null)
const mealDialogVisible = ref(false)
const editingMealId = ref<number | null>(null)
const mealForm = ref({
  dishId: undefined as number | undefined,
  dishSource: 1,
  sort: 1,
})
const flightsPage = ref(1)
const flightsPageSize = ref(10)
const mealsPage = ref(1)
const mealsPageSize = ref(10)

const filteredFlights = computed(() => {
  const keyword = flightNumberQuery.value.trim().toUpperCase()
  if (!keyword) return allFlights.value
  return allFlights.value.filter((item) => (item.flightNumber || '').toUpperCase().includes(keyword))
})

const pagedFlights = computed(() => {
  const start = (flightsPage.value - 1) * flightsPageSize.value
  return filteredFlights.value.slice(start, start + flightsPageSize.value)
})

const pagedMeals = computed(() => {
  const start = (mealsPage.value - 1) * mealsPageSize.value
  return mealBindings.value.slice(start, start + mealsPageSize.value)
})

const loadFlights = async () => {
  loading.value = true
  const { data: res } = await getFlightListAPI()
  loading.value = false
  if (res.code !== 0) return
  allFlights.value = res.data || []
}

const loadMeals = async (flightNumber: string) => {
  mealLoading.value = true
  const { data: res } = await getFlightMealsAPI(flightNumber)
  mealLoading.value = false
  if (res.code !== 0) return
  mealBindings.value = res.data || []
}

const loadDishOptions = async () => {
  const { data: res } = await getDishPageListAPI({ page: 1, pageSize: 5000, status: 1 })
  if (res.code !== 0) return
  const records = (res.data as any)?.records || []
  dishOptions.value = records
    .filter((item: any) => item?.id)
    .map((item: any) => ({
      id: Number(item.id),
      name: String(item.name || `餐食#${item.id}`),
      status: Number(item.status ?? 1),
    }))
}

const selectFlight = async (row: FlightItem) => {
  selectedFlight.value = row
  await loadMeals(row.flightNumber)
}

const search = () => {
  if (!filteredFlights.value.length) {
    selectedFlight.value = null
    mealBindings.value = []
    return
  }
  selectFlight(filteredFlights.value[0])
}

const reset = () => {
  flightNumberQuery.value = ''
  selectedFlight.value = null
  mealBindings.value = []
  flightsPage.value = 1
  mealsPage.value = 1
}

const openAddMealDialog = () => {
  if (!selectedFlight.value) {
    ElMessage.warning('请先选择航班')
    return
  }
  if (!dishOptions.value.length) {
    ElMessage.warning('暂无可绑定餐食，请先在餐食资源中心新增并启用餐食')
    return
  }
  editingMealId.value = null
  mealForm.value = {
    dishId: undefined,
    dishSource: 1,
    sort: (mealBindings.value?.length || 0) + 1,
  }
  mealDialogVisible.value = true
}

const openEditMealDialog = (row: FlightMealBindingItem) => {
  editingMealId.value = row.id
  mealForm.value = {
    dishId: row.dishId,
    dishSource: row.dishSource || 1,
    sort: row.sort || 1,
  }
  mealDialogVisible.value = true
}

const saveMeal = async () => {
  if (!selectedFlight.value) {
    ElMessage.warning('请先选择航班')
    return
  }
  if (!mealForm.value.dishId) {
    ElMessage.warning('请选择餐食')
    return
  }
  const payload: FlightMealBindingUpsertPayload = {
    flightNumber: selectedFlight.value.flightNumber,
    dishId: mealForm.value.dishId,
    dishSource: mealForm.value.dishSource || 1,
    sort: mealForm.value.sort || 1,
  }
  if (editingMealId.value) {
    const { data: res } = await updateFlightMealAPI({ ...payload, id: editingMealId.value })
    if (res.code !== 0) return
    ElMessage.success('航班餐食已更新')
  } else {
    const { data: res } = await addFlightMealAPI(payload)
    if (res.code !== 0) return
    ElMessage.success('航班餐食新增成功')
  }
  mealDialogVisible.value = false
  await loadMeals(selectedFlight.value.flightNumber)
}

const removeMeal = (row: FlightMealBindingItem) => {
  ElMessageBox.confirm('确认删除该航班餐食绑定吗？删除后不可恢复。', '提示', {
    type: 'warning',
  })
    .then(async () => {
      const { data: res } = await deleteFlightMealAPI(row.id)
      if (res.code !== 0) return
      ElMessage.success('航班餐食删除成功')
      if (selectedFlight.value) {
        await loadMeals(selectedFlight.value.flightNumber)
      }
    })
    .catch(() => {})
}

onMounted(async () => {
  await Promise.all([loadFlights(), loadDishOptions()])
})
</script>

<template>
  <div class="page" v-loading="loading">
    <el-card>
      <template #header>
        <div class="header-row">
          <span>航班餐食中心</span>
          <el-button @click="loadFlights">刷新</el-button>
        </div>
      </template>

      <el-form inline>
        <el-form-item label="航班号">
          <el-input v-model="flightNumberQuery" placeholder="请输入航班号" clearable />
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
        <el-table-column label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 1 ? 'success' : 'info'">
              {{ scope.row.status === 1 ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="餐食管理" width="120">
          <template #default="scope">
            <el-button type="primary" link @click="selectFlight(scope.row)">查看餐食</el-button>
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

    <el-card style="margin-top: 14px" v-loading="mealLoading">
      <template #header>
        <div class="header-row">
          <span>当前航班餐食绑定信息</span>
          <div style="display: flex; align-items: center; gap: 12px">
            <span v-if="selectedFlight" style="color: #409eff">
              {{ selectedFlight.flightNumber }}（{{ selectedFlight.departure }} → {{ selectedFlight.destination }}）
            </span>
            <el-button type="primary" @click="openAddMealDialog" :disabled="!selectedFlight">新增餐食</el-button>
          </div>
        </div>
      </template>

      <el-table :data="pagedMeals" border stripe>
        <el-table-column prop="id" label="绑定ID" width="90" />
        <el-table-column prop="dishId" label="餐食ID" width="90" />
        <el-table-column prop="dishName" label="餐食名称" min-width="180" />
        <el-table-column label="餐食状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.dishStatus === 1 ? 'success' : 'info'">
              {{ scope.row.dishStatus === 1 ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="来源" width="100">
          <template #default="scope">
            {{ scope.row.dishSource === 1 ? '系统推荐' : '人工指定' }}
          </template>
        </el-table-column>
        <el-table-column prop="sort" label="排序" width="80" />
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="scope">
            <el-button type="primary" link @click="openEditMealDialog(scope.row)">编辑</el-button>
            <el-button type="danger" link @click="removeMeal(scope.row)">删除</el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty :description="selectedFlight ? '当前航班暂无餐食绑定' : '请先选择航班查看餐食绑定信息'" />
        </template>
      </el-table>
      <el-pagination
        class="table-pagination"
        v-model:current-page="mealsPage"
        v-model:page-size="mealsPageSize"
        :page-sizes="[10, 15, 20]"
        :total="mealBindings.length"
        layout="total, sizes, prev, pager, next, jumper"
        background
      />
    </el-card>

    <el-dialog v-model="mealDialogVisible" :title="editingMealId ? '编辑航班餐食' : '新增航班餐食'" width="520px">
      <el-form label-width="100px">
        <el-form-item label="餐食" required>
          <el-select v-model="mealForm.dishId" placeholder="请选择餐食" style="width: 100%" filterable>
            <el-option v-for="item in dishOptions" :key="item.id" :label="`${item.name}（ID:${item.id}）`" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="来源">
          <el-radio-group v-model="mealForm.dishSource">
            <el-radio :value="1">系统推荐</el-radio>
            <el-radio :value="2">人工指定</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="mealForm.sort" :min="1" :max="999" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="mealDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveMeal">保存</el-button>
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
