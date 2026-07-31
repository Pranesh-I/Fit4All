import { createContext, useContext, useState } from 'react'
import axios from 'axios'

const AuthContext = createContext()

export const AuthProvider = ({ children }) => {
  const [token, setToken] = useState(localStorage.getItem('adminToken'))

  const login = async (username, password) => {
    const response = await axios.post('http://localhost:8000/admin/login', { username, password })
    const { access_token } = response.data
    localStorage.setItem('adminToken', access_token)
    setToken(access_token)
  }

  const logout = () => {
    localStorage.removeItem('adminToken')
    setToken(null)
  }

  return (
    <AuthContext.Provider value={{ token, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
