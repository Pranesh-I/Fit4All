import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import LoginPage from './pages/LoginPage'
import SessionPage from './pages/SessionPage'
import SubmissionPage from './pages/SubmissionPage'
import { AuthProvider, useAuth } from './context/AuthContext'

const ProtectedRoute = ({ children }) => {
  const { token } = useAuth()
  if (!token) return <Navigate to="/login" />
  return children
}

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/sessions" element={<ProtectedRoute><SessionPage /></ProtectedRoute>} />
          <Route path="/submissions" element={<ProtectedRoute><SubmissionPage /></ProtectedRoute>} />
          <Route path="/" element={<Navigate to="/sessions" />} />
        </Routes>
      </Router>
    </AuthProvider>
  )
}

export default App
