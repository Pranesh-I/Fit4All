import { useEffect, useState } from 'react'
import { Box, Container, Typography, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Chip } from '@mui/material'
import Sidebar from '../components/Sidebar'
import AthleteDetailsModal from '../components/AthleteDetailsModal'
import axios from 'axios'
import { useAuth } from '../context/AuthContext'
import dayjs from 'dayjs'

const SubmissionPage = () => {
  const [submissions, setSubmissions] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedSubmissionId, setSelectedSubmissionId] = useState(null)
  const [modalOpen, setModalOpen] = useState(false)
  const { token } = useAuth()

  const openAthleteModal = (id) => {
    setSelectedSubmissionId(id)
    setModalOpen(true)
  }

  useEffect(() => {
    const fetchSubmissions = async () => {
      try {
        const res = await axios.get('http://localhost:8000/admin/submissions', {
          headers: { Authorization: `Bearer ${token}` }
        })
        setSubmissions(res.data)
      } catch (err) {
        console.error(err)
      } finally {
        setLoading(false)
      }
    }
    fetchSubmissions()
  }, [token])

  return (
    <Box sx={{ display: 'flex' }}>
      <Sidebar />
      <Box component="main" sx={{ flexGrow: 1, p: 3, mt: 8 }}>
        <Container maxWidth="xl">
          <Typography variant="h4" gutterBottom fontWeight="bold" color="primary">
            Athlete Submissions
          </Typography>
          <Typography variant="body2" color="textSecondary" sx={{ mb: 3 }}>
            Showing results filtered by current active session window.
          </Typography>

          <TableContainer component={Paper} sx={{ boxShadow: '0 4px 20px rgba(0,0,0,0.05)' }}>
            <Table stickyHeader>
              <TableHead>
                <TableRow>
                  <TableCell sx={{ fontWeight: 'bold', bgcolor: '#f8f9fa' }}>Athlete Name</TableCell>
                  <TableCell sx={{ fontWeight: 'bold', bgcolor: '#f8f9fa' }}>Location</TableCell>
                  <TableCell align="center" sx={{ fontWeight: 'bold', bgcolor: '#f8f9fa' }}>Total</TableCell>
                  <TableCell align="center" sx={{ fontWeight: 'bold', bgcolor: '#f8f9fa' }}>Correct</TableCell>
                  <TableCell align="center" sx={{ fontWeight: 'bold', bgcolor: '#f8f9fa' }}>Incorrect</TableCell>
                  <TableCell align="center" sx={{ fontWeight: 'bold', bgcolor: '#f8f9fa' }}>Accuracy</TableCell>
                  <TableCell align="center" sx={{ fontWeight: 'bold', bgcolor: '#f8f9fa' }}>Confidence</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 'bold', bgcolor: '#f8f9fa' }}>Date</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {submissions.map((row) => (
                  <TableRow 
                    key={row.test_id} 
                    hover 
                    onClick={() => openAthleteModal(row.id)}
                    sx={{ cursor: 'pointer' }}
                  >
                    <TableCell sx={{ fontWeight: 500 }}>{row.athlete_name}</TableCell>
                    <TableCell>{row.district}, {row.state}</TableCell>
                    <TableCell align="center">{row.total_reps}</TableCell>
                    <TableCell align="center" sx={{ color: 'success.main', fontWeight: 'bold' }}>{row.correct_reps}</TableCell>
                    <TableCell align="center" sx={{ color: 'error.main' }}>{row.incorrect_reps}</TableCell>
                    <TableCell align="center">
                      <Chip
                        label={`${row.accuracy.toFixed(1)}%`}
                        color={row.accuracy >= 80 ? "success" : row.accuracy >= 50 ? "warning" : "error"}
                        variant="outlined"
                        size="small"
                      />
                    </TableCell>
                    <TableCell align="center">{(row.pose_confidence_score * 100).toFixed(0)}%</TableCell>
                    <TableCell align="right" color="textSecondary">
                      {dayjs(row.recorded_at).format('DD MMM YYYY HH:mm')}
                    </TableCell>
                  </TableRow>
                ))}
                {!loading && submissions.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={8} align="center" sx={{ py: 10 }}>
                      <Typography variant="h6" color="textSecondary">No submissions found for the active session.</Typography>
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Container>
      </Box>

      <AthleteDetailsModal
        open={modalOpen}
        submissionId={selectedSubmissionId}
        onClose={() => setModalOpen(false)}
      />
    </Box>
  )
}

export default SubmissionPage
