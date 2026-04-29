import { bindFlightAPI, getCurrentFlightAPI, getFlightListAPI } from '@/api/flight'
import { getUserInfoAPI } from '@/api/user'
import type { FlightInfo } from '@/types/aviation'
import { useAuthGuard } from './useAuthGuard'

export const useFlightContext = () => {
  const { userStore, ensureLogin } = useAuthGuard()

  const loadFlightContext = async () => {
    if (!ensureLogin()) {
      return {
        ok: false,
        needIdentity: true,
        currentFlight: null as FlightInfo | null,
        candidateFlights: [] as FlightInfo[],
      }
    }

    const userRes = await getUserInfoAPI(userStore.profile!.id)
    const idNumber = userRes.data?.idNumber
    if (!idNumber) {
      return {
        ok: false,
        needIdentity: true,
        currentFlight: null as FlightInfo | null,
        candidateFlights: [] as FlightInfo[],
      }
    }

    const [currentRes, candidateRes] = await Promise.all([getCurrentFlightAPI(), getFlightListAPI(idNumber)])
    let currentFlight = currentRes.data || null
    let candidateFlights = candidateRes.data || []

    // 过滤已到达的航班
    const now = new Date()
    const isFlightEnded = (f: FlightInfo | null) => {
      if (!f?.arrivalTime) return false
      const normalized = String(f.arrivalTime).replace(' ', 'T')
      const t = new Date(normalized)
      return !isNaN(t.getTime()) && t <= now
    }
    candidateFlights = candidateFlights.filter(f => !isFlightEnded(f))
    if (currentFlight && isFlightEnded(currentFlight)) {
      currentFlight = null
    }

    if (!currentFlight && candidateFlights.length > 0) {
      const defaultFlight = candidateFlights[0]
      await bindFlightAPI(defaultFlight.id)
      currentFlight = defaultFlight
    }

    return {
      ok: !!currentFlight,
      needIdentity: false,
      currentFlight,
      candidateFlights,
    }
  }

  return {
    loadFlightContext,
  }
}
