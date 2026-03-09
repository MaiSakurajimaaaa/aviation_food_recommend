export const isSuperAdmin = (account?: string | null): boolean => {
  if (!account) {
    return false
  }
  return account === 'admin'
}
