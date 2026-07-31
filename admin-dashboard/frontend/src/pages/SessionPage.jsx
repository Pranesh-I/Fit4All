import { useState, useEffect } from 'react'
import { Box, Container, Typography, TextField, Button, Paper, Grid, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Chip } from '@mui/material'
import Sidebar from '../components/Sidebar'
import axios from 'axios'
import { useAuth } from '../context/AuthContext'

const SessionPage = () => {
  const [sessions, setSessions] = useState([])
  const [form, setForm] = useState({ session_name: '', start_date: '', end_date: '', test_type: 'squat' })
  const { token } = useAuth()

  const fetchSessions = async () => {
    try {
      const res = await axios.get('http://localhost:8000/admin/sessions', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setSessions(res.data)
    } catch (err) {
      console.error(err)
    }
  }

  useEffect(() => { fetchSessions() }, [token])

  const handleSubmit = async (e) => {
    e.preventDefault()
    try {
      await axios.post('http://localhost:8000/admin/create-session', form, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setForm({ session_name: '', start_date: '', end_date: '', test_type: 'squat' })
      fetchSessions()
    } catch (err) {
      alert('Failed to create session')
    }
  }

  return (
    <Box sx={{ display: 'flex' }}>
      <Sidebar />
      <Box component="main" sx={{ flexGrow: 1, p: 3, mt: 8 }}>
        <Container maxWidth="lg">
          <Typography variant="h4" gutterBottom fontWeight="bold" color="primary">
            Assessment Sessions
          </Typography>

          <Paper sx={{ p: 4, mb: 4 }}>
            <Typography variant="h6" gutterBottom>Create New Session</Typography>
            <form onSubmit={handleSubmit}>
              <Grid container spacing={2}>
                <Grid item xs={12} md={4}>
                  <TextField fullWidth label="Session Name" value={form.session_name} onChange={(e) => setForm({ ...form, session_name: e.target.value })} required />
                </Grid>
                <Grid item xs={12} md={3}>
                  <TextField fullWidth type="date" label="Start Date" InputLabelProps={{ shrink: true }} value={form.start_date} onChange={(e) => setForm({ ...form, start_date: e.target.value })} required />
                </Grid>
                <Grid item xs={12} md={3}>
                  <TextField fullWidth type="date" label="End Date" InputLabelProps={{ shrink: true }} value={form.end_date} onChange={(e) => setForm({ ...form, end_date: e.target.value })} required />
                </Grid>
                <Grid item xs={12} md={2}>
                  <Button fullWidth variant="contained" size="large" sx={{ height: '100%' }} type="submit">Create</Button>
                </Grid>
              </Grid>
            </form>
          </Paper>

          <TableContainer component={Paper}>
            <Table>
              <TableHead sx={{ bgcolor: '#f5f5f5' }}>
                <TableRow>
                  <TableCell>Session Name</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell>Start</TableCell>
                  <TableCell>End</TableCell>
                  <TableCell>Status</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {sessions.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} align="center" sx={{ py: 5 }}>
                      <Typography variant="body1" color="textSecondary">
                        No active sessions available. Create a session to begin assessment.
                      </Typography>
                    </TableCell>
                  </TableRow>
                )}
                {sessions.map((s) => (
                  <TableRow key={s.id}>
                    <TableCell fontWeight="bold">{s.session_name}</TableCell>
                    <TableCell>{s.test_type.toUpperCase()}</TableCell>
                    <TableCell>{s.start_date}</TableCell>
                    <TableCell>{s.end_date}</TableCell>
                    <TableCell>
                      <Chip
                        label={s.is_active ? "Active" : "Closed"}
                        color={s.is_active ? "success" : "default"}
                        size="small"
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Container>
      </Box>
    </Box>
  )
}

export default SessionPage
