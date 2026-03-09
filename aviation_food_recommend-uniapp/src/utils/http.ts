import { useUserStore } from '@/stores/modules/user'

// 请求基地址
const baseURL = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8081').trim()
const isLoopbackBase = /localhost|127\.0\.0\.1/.test(baseURL)
let redirectingToLogin = false

// 拦截器配置
const httpInterceptor = {
  // 拦截前触发
  invoke(options: UniApp.RequestOptions) {
    // 1. 非 http 开头需拼接地址
    if (!options.url.startsWith('http')) {
      options.url = baseURL + options.url
    }
    // 2. 请求超时
    options.timeout = 10000
    // 3. 添加小程序端请求头标识
    options.header = {
      'source-client': 'miniapp',
      ...options.header,
    }
    // 4. 添加 token 请求头标识
    const userStore = useUserStore()
    const token = userStore.profile?.token
    if (token) {
      options.header.Authorization = token
    }
  },
}

// 拦截 request 请求
uni.addInterceptor('request', httpInterceptor)
// 拦截 uploadFile 文件上传
// uni.addInterceptor('uploadFile', httpInterceptor)

// 定义泛型接口
interface Data<T> {
  code: number
  msg: string
  data: T
}

type HttpRequestOptions = UniApp.RequestOptions & {
  suppressErrorToast?: boolean
}

const showErrorToast = (title: string, suppressErrorToast?: boolean) => {
  if (suppressErrorToast) {
    return
  }
  uni.showToast({
    title,
    icon: 'none',
  })
}

const redirectToLoginOnce = () => {
  if (redirectingToLogin) {
    return
  }
  redirectingToLogin = true
  setTimeout(() => {
    uni.reLaunch({ url: '/pages/login/login' })
    redirectingToLogin = false
  }, 0)
}

// 相比axios，uniapp对ts不友好，因此自己封装函数升级request，实现响应拦截器的功能
// 直观体现： wx.request({}) -> async await promise对象
export const http = <T>(options: HttpRequestOptions) => {
  return new Promise<Data<T>>((resolve, reject) => {
    const { suppressErrorToast, ...requestOptions } = options
    uni.request({
      ...requestOptions,
      // 响应成功
      success(res) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          const payload = res.data as Data<T>
          if (typeof payload?.code === 'number' && payload.code !== 0) {
            showErrorToast(payload.msg || '请求失败', suppressErrorToast)
            reject(payload)
            return
          }
          resolve(payload)
        } else if (res.statusCode === 401) {
          const userStore = useUserStore()
          userStore.clearProfile()
          redirectToLoginOnce()
          reject(res)
        } else {
          showErrorToast((res.data as Data<T>)?.msg || '请求失败', suppressErrorToast)
          reject(res)
        }
      },
      // 响应失败
      fail(err) {
        const errMsg = String((err as any)?.errMsg || '')
        const showHint = isLoopbackBase && /ERR_CONNECTION_REFUSED|request:fail|timeout/i.test(errMsg)
        showErrorToast(showHint ? '真机请将接口地址改为电脑局域网IP' : '网络不行，换个试试？', suppressErrorToast)
        reject(err)
      },
    })
  })
}
