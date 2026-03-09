<script setup lang="ts">
import { loginAPI } from '@/api/employee'
import { useRouter } from 'vue-router'
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { useUserInfoStore } from '@/store'
import type { EmployeeLoginDTO } from '@/types/employee'
import type { FormInstance, FormRules } from 'element-plus'

const userInfoStore = useUserInfoStore()

type LoginFormModel = EmployeeLoginDTO & {
  captcha: string
}

const form = ref<LoginFormModel>({
  account: '',
  password: '',
  captcha: ''
})
const captchaText = ref('')

const captchaCanvasRef = ref<HTMLCanvasElement>()

const captchaChars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'
// 表单校验的ref
const loginRef = ref<FormInstance>()

const rules: FormRules = {
  account: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9]{1,10}$/, message: '用户名必须是1-10的字母数字', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { pattern: /^\S{6,15}$/, message: '密码必须是6-15的非空字符', trigger: 'blur' }
  ],
  captcha: [
    { required: true, message: '请输入验证码', trigger: 'blur' }
  ]
}

const router = useRouter()

const randomRange = (min: number, max: number) => Math.floor(Math.random() * (max - min + 1)) + min

const makeCaptchaText = () => {
  let value = ''
  for (let i = 0; i < 4; i++) {
    value += captchaChars[randomRange(0, captchaChars.length - 1)]
  }
  captchaText.value = value
}

const drawCaptcha = () => {
  const canvas = captchaCanvasRef.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  if (!ctx) return

  const width = canvas.width
  const height = canvas.height

  ctx.clearRect(0, 0, width, height)

  const bg = ctx.createLinearGradient(0, 0, width, height)
  bg.addColorStop(0, '#081529')
  bg.addColorStop(1, '#153661')
  ctx.fillStyle = bg
  ctx.fillRect(0, 0, width, height)

  for (let i = 0; i < 24; i++) {
    ctx.strokeStyle = `rgba(140, 225, 255, ${Math.random() * 0.35})`
    ctx.beginPath()
    ctx.moveTo(randomRange(0, width), randomRange(0, height))
    ctx.lineTo(randomRange(0, width), randomRange(0, height))
    ctx.stroke()
  }

  for (let i = 0; i < 28; i++) {
    ctx.fillStyle = `rgba(255, 188, 87, ${Math.random() * 0.45})`
    ctx.beginPath()
    ctx.arc(randomRange(0, width), randomRange(0, height), randomRange(1, 2), 0, Math.PI * 2)
    ctx.fill()
  }

  const chars = captchaText.value.split('')
  chars.forEach((ch, idx) => {
    const x = 18 + idx * 26
    const y = randomRange(26, 36)
    const angle = (Math.random() - 0.5) * 0.55
    ctx.save()
    ctx.translate(x, y)
    ctx.rotate(angle)
    ctx.font = `700 ${randomRange(20, 25)}px "Trebuchet MS", "Segoe UI", sans-serif`
    ctx.fillStyle = idx % 2 === 0 ? '#8ae6ff' : '#ffd17e'
    ctx.fillText(ch, 0, 0)
    ctx.restore()
  })
}

const refreshCaptcha = () => {
  makeCaptchaText()
  drawCaptcha()
}

const loginFn = async () => {
  // 先校验输入格式是否合法
  const valid = await loginRef.value?.validate()
  if (valid) {
    const expected = captchaText.value.trim().toUpperCase()
    const actual = form.value.captcha.trim().toUpperCase()
    if (expected !== actual) {
      ElMessage.error('验证码错误，请重试')
      form.value.captcha = ''
      refreshCaptcha()
      return false
    }

    // 调用登录接口
    const { data: res } = await loginAPI({
      account: form.value.account,
      password: form.value.password
    })
    // 登录失败，提示用户，这个提示已经在响应拦截器中统一处理了，这里直接return就行
    if (res.code !== 0) {
      refreshCaptcha()
      return false
    }
    // 登录成功，提示用户
    ElMessage.success('登录成功')
    // 把后端返回的当前登录用户信息(包括token)存储到Pinia里
    userInfoStore.userInfo = res.data
    // 跳转到首页
    router.push('/')
  } else {
    return false
  }
}

onMounted(() => {
  refreshCaptcha()
})
</script>

<template>
  <div class="login-page">
    <div class="aurora aurora-a"></div>
    <div class="aurora aurora-b"></div>

    <main class="login-layout">
      <section class="brand-panel">
        <p class="tag">AVIATION INTELLIGENCE SYSTEM</p>
        <h1>航空餐食推荐<br />管理端控制台</h1>
        <p class="desc">
          让餐食偏好、航线策略与乘务执行在同一坐标系里协同。精准推荐，从登录这一刻开始。
        </p>
      </section>

      <section class="auth-panel">
        <el-form label-width="0px" class="login-box" :model="form" :rules="rules" ref="loginRef">
          <h2>欢迎回来</h2>
          <p class="sub">账号密码登录 | 不开放自助注册</p>

          <el-form-item prop="account">
            <el-input v-model="form.account" placeholder="请输入管理员账号" autocomplete="username" />
          </el-form-item>

          <el-form-item prop="password">
            <el-input
              type="password"
              show-password
              v-model="form.password"
              placeholder="请输入登录密码"
              autocomplete="current-password"
            />
          </el-form-item>

          <el-form-item prop="captcha">
            <div class="captcha-row">
              <el-input v-model="form.captcha" placeholder="请输入验证码" maxlength="4" />
              <button type="button" class="captcha-box" @click="refreshCaptcha" title="点击刷新验证码">
                <canvas ref="captchaCanvasRef" width="120" height="42"></canvas>
              </button>
            </div>
          </el-form-item>

          <el-form-item class="my-el-form-item">
            <el-button type="primary" class="btn-login" @click="loginFn">登 录</el-button>
          </el-form-item>

          <p class="foot-note">如需开通账号或重置密码，请联系系统管理员。</p>
        </el-form>
      </section>
    </main>
  </div>
</template>


<style lang="less" scoped>
:deep(*) {
  box-sizing: border-box;
}

.login-page {
  --c-bg-1: #040c18;
  --c-bg-2: #0e2644;
  --c-primary: #22c7ff;
  --c-primary-strong: #1497ff;
  --c-accent: #ffb45f;
  --c-text-main: #ecf6ff;
  --c-text-sub: rgba(236, 246, 255, 0.72);

  position: relative;
  min-height: 100vh;
  overflow: hidden;
  background:
    radial-gradient(circle at 18% 8%, rgba(255, 180, 95, 0.22), transparent 24%),
    radial-gradient(circle at 85% 20%, rgba(34, 199, 255, 0.28), transparent 26%),
    linear-gradient(135deg, var(--c-bg-1), var(--c-bg-2));
  color: var(--c-text-main);
}

.aurora {
  position: absolute;
  width: 40vw;
  height: 40vw;
  border-radius: 50%;
  filter: blur(55px);
  opacity: 0.45;
  pointer-events: none;
}

.aurora-a {
  background: #2f7dff;
  top: -14vw;
  left: -7vw;
  animation: floatA 13s ease-in-out infinite;
}

.aurora-b {
  background: #ff9d3f;
  right: -10vw;
  bottom: -12vw;
  animation: floatB 15s ease-in-out infinite;
}

.login-layout {
  position: relative;
  z-index: 2;
  min-height: 100vh;
  display: grid;
  grid-template-columns: 1.1fr 0.9fr;
  gap: 48px;
  align-items: center;
  padding: 60px 7vw;
}

.brand-panel {
  padding-right: 24px;

  .tag {
    margin: 0 0 18px;
    font-size: 13px;
    letter-spacing: 0.22em;
    color: var(--c-accent);
  }

  h1 {
    margin: 0;
    font-size: clamp(34px, 4vw, 60px);
    line-height: 1.14;
    letter-spacing: 0.02em;
    text-wrap: balance;
  }

  .desc {
    margin: 22px 0 0;
    max-width: 580px;
    font-size: clamp(16px, 1.3vw, 20px);
    line-height: 1.7;
    color: var(--c-text-sub);
  }
}

.auth-panel {
  display: flex;
  justify-content: center;
}

.login-box {
  width: min(430px, 100%);
  padding: 32px 28px 24px;
  border-radius: 22px;
  backdrop-filter: blur(16px);
  background: linear-gradient(160deg, rgba(8, 24, 43, 0.76), rgba(12, 34, 60, 0.62));
  border: 1px solid rgba(138, 230, 255, 0.24);
  box-shadow:
    0 24px 54px rgba(0, 0, 0, 0.42),
    inset 0 0 0 1px rgba(255, 255, 255, 0.04);

  h2 {
    margin: 0;
    font-size: 30px;
    font-weight: 700;
    letter-spacing: 0.06em;
    color: #dff6ff;
  }

  .sub {
    margin: 8px 0 24px;
    color: rgba(223, 246, 255, 0.72);
    font-size: 14px;
  }

  :deep(.el-form-item) {
    margin-bottom: 18px;
  }

  :deep(.el-input__wrapper) {
    border-radius: 12px;
    background: rgba(7, 22, 39, 0.65);
    box-shadow: 0 0 0 1px rgba(125, 198, 255, 0.24) inset;
  }

  :deep(.el-input__inner) {
    color: #f4fbff;
  }

  :deep(.el-input__inner::placeholder) {
    color: rgba(186, 219, 248, 0.75);
  }

  .captcha-row {
    display: grid;
    grid-template-columns: 1fr 120px;
    gap: 10px;
    width: 100%;
  }

  .captcha-box {
    height: 42px;
    border: 1px solid rgba(130, 202, 255, 0.42);
    border-radius: 10px;
    overflow: hidden;
    padding: 0;
    background: #0d2038;
    cursor: pointer;
  }

  .captcha-box canvas {
    display: block;
    width: 100%;
    height: 100%;
  }

  .my-el-form-item {
    margin-top: 6px;
  }

  .btn-login {
    width: 100%;
    height: 44px;
    border: none;
    border-radius: 12px;
    letter-spacing: 0.16em;
    font-weight: 700;
    background: linear-gradient(110deg, var(--c-primary), var(--c-primary-strong));
    box-shadow: 0 12px 22px rgba(34, 147, 255, 0.4);
    transition: transform 0.22s ease, filter 0.22s ease;
  }

  .btn-login:hover {
    transform: translateY(-1px);
    filter: brightness(1.06);
  }

  .foot-note {
    margin: 6px 0 0;
    text-align: center;
    color: rgba(204, 233, 255, 0.76);
    font-size: 12px;
    letter-spacing: 0.03em;
  }
}

@keyframes floatA {
  0%,
  100% {
    transform: translate3d(0, 0, 0) scale(1);
  }
  50% {
    transform: translate3d(22px, 16px, 0) scale(1.08);
  }
}

@keyframes floatB {
  0%,
  100% {
    transform: translate3d(0, 0, 0) scale(1);
  }
  50% {
    transform: translate3d(-24px, -12px, 0) scale(1.06);
  }
}

@media (max-width: 980px) {
  .login-layout {
    grid-template-columns: 1fr;
    gap: 26px;
    padding: 34px 20px;
  }

  .brand-panel {
    text-align: center;
    padding-right: 0;

    .desc {
      margin-inline: auto;
    }
  }

  .login-box {
    width: min(500px, 100%);
  }
}

@media (max-width: 520px) {
  .brand-panel .tag {
    font-size: 11px;
  }

  .brand-panel h1 {
    font-size: 30px;
  }

  .login-box {
    padding: 24px 16px 18px;
  }

  .login-box .captcha-row {
    grid-template-columns: 1fr 108px;
  }
}
</style>