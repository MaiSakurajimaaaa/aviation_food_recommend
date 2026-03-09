<script setup lang="ts" name="layout">
import { RouterView, useRouter, useRoute } from 'vue-router'
import { ElMessageBox, ElMessage } from 'element-plus'
import { useUserInfoStore } from '@/store'
import { ref, reactive, computed } from 'vue'
import { fixPwdAPI } from '@/api/employee'
import type { FormInstance, FormRules } from 'element-plus'
import { isSuperAdmin } from '@/utils/authz'

// ------ data ------
const dialogFormVisible = ref(false)
const formLabelWidth = '80px'
const isCollapse = ref(false)

const menuList = [
  {
    title: '航空总览',
    path: '/dashboard',
    icon: 'pieChart',
  },
  {
    title: '航班运营中心',
    path: '/flights',
    icon: 'Guide',
  },
  {
    title: '航班管理中心',
    path: '/flight-center',
    icon: 'DataLine',
  },
  {
    title: '航班餐食中心',
    path: '/flight-meal-center',
    icon: 'Food',
  },
  {
    title: '用户餐食中心',
    path: '/user-meal-center',
    icon: 'User',
  },
  {
    title: '餐食资源中心',
    path: '/foods',
    icon: 'Food',
  },
  {
    title: '公告管理中心',
    path: '/preferences',
    icon: 'DataAnalysis',
  },
  {
    title: '评分管理中心',
    path: '/rating-center',
    icon: 'Star',
  },
  {
    title: '管理人员',
    path: '/employee',
    icon: 'setting',
  },
]

const form = reactive({
  oldPwd: '',
  newPwd: '',
  rePwd: '',
})
const pwdRef = ref<FormInstance>()
const status = ref(1)

// 自定义校验规则: 两次密码是否一致
const samePwd = (_rule: unknown, value: string, callback: (error?: Error) => void) => {
  if (value !== form.newPwd) {
    // 如果验证失败，则调用 回调函数时，指定一个 Error 对象。
    callback(new Error('两次输入的密码不一致!'))
  } else {
    // 如果验证成功，则直接调用 callback 回调函数即可。
    callback()
  }
}
const rules: FormRules = { // 表单的规则检验对象
  oldPwd: [
    { required: true, message: '请输入原密码', trigger: 'blur' },
    {
      pattern: /^[a-zA-Z0-9]{1,10}$/,
      message: '原密码必须是1-10的大小写字母数字',
      trigger: 'blur'
    }
  ],
  newPwd: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { pattern: /^\S{6,15}$/, message: '新密码必须是6-15的非空字符', trigger: 'blur' }
  ],
  rePwd: [
    { required: true, message: '请再次输入新密码', trigger: 'blur' },
    { pattern: /^\S{6,15}$/, message: '新密码必须是6-15的非空字符', trigger: 'blur' },
    { validator: samePwd, trigger: 'blur' }
  ]
}

// ------ method ------
const router = useRouter()
const userInfoStore = useUserInfoStore()
const route = useRoute();
// 根据当前路由的路径返回要激活的菜单项
const getActiveAside = () => {
  return route.path;
};
const visibleMenuList = computed(() => {
  const currentAccount = userInfoStore.userInfo?.account
  return menuList.filter((item) => item.path !== '/employee' || isSuperAdmin(currentAccount))
})
// 关闭修改密码对话框
const cancelForm = () => {
  ElMessage({
    type: 'info',
    message: '已取消修改',
  })
  dialogFormVisible.value = false
}
// 修改密码
const fixPwd = async () => {
  const valid = await pwdRef.value?.validate()
  if (valid) {
    const submitForm = {
      oldPwd: form.oldPwd,
      newPwd: form.newPwd,
    }
    const { data: res } = await fixPwdAPI(submitForm)
    if (res.code != 0) return   // 密码错误信息会在相应拦截器中捕获并提示
    ElMessage({
      type: 'success',
      message: '修改成功',
    })
    dialogFormVisible.value = false
  } else {
    return false
  }
}

const quitFn = () => {
  // 为了让用户体验更好，来个确认提示框
  ElMessageBox.confirm(
    '走了，爱是会消失的吗?',
    '退出登录',
    {
      confirmButtonText: 'OK',
      cancelButtonText: 'Cancel',
      type: 'warning',
    }
  )
    .then(() => {
      ElMessage({
        type: 'success',
        message: '退出成功',
      })
      // 清除用户信息，包括token
      userInfoStore.userInfo = null
      router.push('/login')
    })
    .catch(() => {
      ElMessage({
        type: 'info',
        message: '已取消退出',
      })
    })
}
</script>

<template>
  <div class="common-layout">
    <el-dialog v-model="dialogFormVisible" title="修改密码" width="500">
      <el-form :model="form" :rules="rules" ref="pwdRef">
        <el-form-item prop="oldPwd" label="原密码" :label-width="formLabelWidth">
          <el-input v-model="form.oldPwd" autocomplete="off" />
        </el-form-item>
        <el-form-item prop="newPwd" label="新密码" :label-width="formLabelWidth">
          <el-input v-model="form.newPwd" autocomplete="off" />
        </el-form-item>
        <el-form-item prop="rePwd" label="确认密码" :label-width="formLabelWidth">
          <el-input v-model="form.rePwd" autocomplete="off" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="cancelForm">取消</el-button>
          <el-button type="primary" @click="fixPwd">确定</el-button>
        </div>
      </template>
    </el-dialog>
    <el-container>
      <el-header>
        <div class="logo-text">航空旅客智能美食推荐系统</div>
        <el-icon class="icon1" v-if="isCollapse">
          <Expand @click.stop="isCollapse = !isCollapse" />
        </el-icon>
        <el-icon class="icon1" v-else>
          <Fold @click.stop="isCollapse = !isCollapse" />
        </el-icon>
        <div class="status">{{ status == 1 ? '航空推荐模式' : "维护模式" }}</div>
        <el-dropdown style="float: right">
          <el-button type="primary">
            {{ userInfoStore.userInfo ? userInfoStore.userInfo.account : '未登录' }}
            <el-icon class="arrow-down-icon"><arrow-down /></el-icon>
          </el-button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item @click="dialogFormVisible = true">修改密码</el-dropdown-item>
              <el-dropdown-item @click="quitFn">退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </el-header>
      <el-container class="box1">
        <!-- 左侧导航菜单区域 -->
        <el-menu :width="isCollapse ? '640px' : '200px'" :default-active="getActiveAside()" :collapse="isCollapse"
          background-color="#22aaee" text-color="#fff" unique-opened router>
          <!-- 加了router模式，就会在激活导航时以 :index 作为path进行路径跳转（nb!不用自己写路由了!） -->
          <!-- 根据不同情况选择menu-item/submenu进行遍历，所以外层套template遍历，里面组件做判断看是否该次遍历到自己 -->
          <template v-for="item in visibleMenuList" :key="item.path">
            <el-menu-item :index="item.path">
              <el-icon>
                <component :is="item.icon" />
              </el-icon>
              <span>{{ item.title }}</span>
            </el-menu-item>
          </template>
        </el-menu>

        <el-container class="mycontainer">
          <el-main>
            <router-view></router-view>
          </el-main>
          <el-footer>© 2026 航空旅客智能美食推荐系统 · Graduation Project</el-footer>
        </el-container>
      </el-container>
    </el-container>
  </div>
</template>

<style lang="less" scoped>
.common-layout {
  height: 100%;
  background-color: #eee;
}

.el-header {
  background-color: #00aaff;
  color: #ffffff;
  line-height: 60px;

  .logo-text {
    display: inline-block;
    margin: 0 20px;
    font-size: 18px;
    font-weight: 700;
    color: #fff;
    letter-spacing: 1px;
  }

  .icon1 {
    position: absolute;
    top: 18px;
    margin: 5px 10px 0 0;
  }

  .status {
    display: inline-block;
    align-items: center;
    vertical-align: top;
    line-height: 30px;
    margin: 15px 50px;
    padding: 0 10px;
    border-radius: 5px;
    background-color: #eebb00;
    color: #fff;
  }
}

.user {
  float: right;
  margin-right: 20px;
}

.el-dropdown .el-button {
  float: right;
  width: 80px;
  margin: 14px 20px;
  background-color: #eebb00;
  border-color: #eebb00;
  color: #fff;

  .arrow-down-icon {
    margin-left: 5px;
  }
}

.box1 {
  display: flex;
  height: 92vh;
}

.mycontainer {
  display: flex;
  flex: 6;
  flex-direction: column;
}

.el-main {
  flex: 1;
  background-color: #e9f5ff;
  color: #333;
  /* text-align: center; */
  /* line-height: 80px; */
}

a {
  display: block;
  height: 4rem;
  color: #334455;
  font-size: 20px;
  font-weight: bold;
  text-decoration: none;
}

a:hover {
  background-color: #445566;
  color: #eee;
}

.el-footer {
  background-color: #eee;
  font-size: 12px;
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>



<style lang="less">
.el-dialog {
  border-radius: 2%;
}

.el-dialog__header {
  height: 60px;
  line-height: 60px;
  padding: 0 30px;
  font-weight: bold;
}

.el-dialog__body {
  padding: 10px 30px 30px;
}

.el-badge__content.is-fixed {
  top: 24px;
  right: 2px;
  width: 18px;
  height: 18px;
  font-size: 10px;
  line-height: 16px;
  font-size: 10px;
  border-radius: 50%;
  padding: 0;
}

.badgeW {
  .el-badge__content.is-fixed {
    width: 30px;
    border-radius: 20px;
  }
}

.el-menu {
  padding: 30px 0 0 0;
  background-color: #445566;
}

.el-menu-item {
  margin: 10px;
  padding-right: 30px;
  border-radius: 10px;
}

.el-menu-item.is-active {
  background-color: #22ccff;
  color: #fff;
}

.el-menu--collapse {
  width: 85px;
}
</style>