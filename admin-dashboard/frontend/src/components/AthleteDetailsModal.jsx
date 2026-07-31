import { useState, useEffect } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Grid,
  Divider,
  Box,
  Chip,
  CircularProgress
} from '@mui/material'
import axios from 'axios'
import { useAuth } from '../context/AuthContext'
import dayjs from 'dayjs'

const AthleteDetailsModal = ({ open, submissionId, onClose }) => {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)
  const { token } = useAuth()

  useEffect(() => {
    if (open && submissionId) {
      const fetchDetails = async () => {
        setLoading(true)
        try {
          const res = await axios.get(`http://localhost:8000/admin/submissions/${submissionId}`, {
            headers: { Authorization: `Bearer ${token}` }
          })
          setData(res.data)
        } catch (err) {
          console.error(err)
        } finally {
          setLoading(false)
        }
      }
      fetchDetails()
    }
  }, [open, submissionId, token])

  const getAccuracyColor = (acc) => {
    if (acc >= 85) return 'success'
    if (acc >= 60) return 'warning'
    return 'error'
  }

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ bgcolor: '#f8f9fa', fontWeight: 'bold' }}>
        Athlete Performance Details
      </DialogTitle>
      <DialogContent dividers>
        {loading || !data ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 5 }}>
            <CircularProgress />
          </Box>
        ) : (
          <Box sx={{ pt: 1 }}>
            <Grid container spacing={3}>
              {/* Profile Section */}
              <Grid item xs={12}>
                <Typography variant="subtitle2" color="textSecondary" gutterBottom>
                  ATHLETE PROFILE
                </Typography>
                <Typography variant="h5" fontWeight="bold" color="primary">
                  {data.athlete_name}
                </Typography>
                <Typography variant="body1">
                  {data.district}, {data.state}
                </Typography>
                <Typography variant="body2" sx={{ mt: 0.5 }}>
                  <strong>Phone:</strong> {data.mobile_number || "Not Available"}
                </Typography>
                <Box sx={{ mt: 1, display: 'flex', gap: 2 }}>
                  <Typography variant="body2">
                    <strong>Height:</strong> {data.height_cm} cm
                  </Typography>
                  <Typography variant="body2">
                    <strong>Weight:</strong> {data.weight_kg} kg
                  </Typography>
                </Box>
              </Grid>

              <Grid item xs={12}><Divider /></Grid>

              {/* Assessment Section */}
              <Grid item xs={12}>
                <Typography variant="subtitle2" color="textSecondary" gutterBottom>
                  ASSESSMENT DETAILS
                </Typography>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="h6" fontWeight="bold">
                    {data.session_name}
                  </Typography>
                  <Chip label="SQUAT TEST" size="small" variant="outlined" color="primary" />
                </Box>
                <Typography variant="caption" color="textSecondary">
                  Submitted on {dayjs(data.recorded_at).format('DD MMM YYYY, hh:mm A')}
                </Typography>
              </Grid>

              <Grid item xs={4}>
                <Typography variant="body2" color="textSecondary">Total Reps</Typography>
                <Typography variant="h5" fontWeight="bold">{data.total_reps}</Typography>
              </Grid>
              <Grid item xs={4}>
                <Typography variant="body2" color="textSecondary">Correct</Typography>
                <Typography variant="h5" fontWeight="bold" color="success.main">{data.correct_reps}</Typography>
              </Grid>
              <Grid item xs={4}>
                <Typography variant="body2" color="textSecondary">Incorrect</Typography>
                <Typography variant="h5" fontWeight="bold" color="error.main">{data.incorrect_reps}</Typography>
              </Grid>

              <Grid item xs={6}>
                <Typography variant="body2" color="textSecondary">Accuracy</Typography>
                <Chip 
                  label={`${data.accuracy.toFixed(1)}%`} 
                  color={getAccuracyColor(data.accuracy)}
                  sx={{ mt: 0.5, fontWeight: 'bold' }}
                />
              </Grid>
              <Grid item xs={6}>
                <Typography variant="body2" color="textSecondary">Confidence Score</Typography>
                <Typography variant="h6" fontWeight="bold">
                  {(data.pose_confidence_score * 100).toFixed(0)}%
                </Typography>
              </Grid>
            </Grid>
          </Box>
        )}
      </DialogContent>
      <DialogActions sx={{ p: 2, bgcolor: '#f8f9fa' }}>
        <Button onClick={onClose} variant="outlined" color="inherit">
          Close
        </Button>
      </DialogActions>
    </Dialog>
  )
}

export default AthleteDetailsModal
