import { Drawer, List, ListItem, ListItemIcon, ListItemText, Toolbar, Typography, Divider, Box } from '@mui/material'
import { Event, Assignment, Logout } from '@mui/icons-material'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const drawerWidth = 240

const Sidebar = () => {
  const navigate = useNavigate()
  const { logout } = useAuth()

  const menuItems = [
    { text: 'Sessions', icon: <Event />, path: '/sessions' },
    { text: 'Submissions', icon: <Assignment />, path: '/submissions' },
  ]

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        [`& .MuiDrawer-paper`]: { width: drawerWidth, boxSizing: 'border-box', bgcolor: '#1a237e', color: 'white' },
      }}
    >
      <Toolbar>
        <Typography variant="h6" noWrap component="div" fontWeight="bold">
          SAI Portal
        </Typography>
      </Toolbar>
      <Divider sx={{ bgcolor: 'rgba(255,255,255,0.1)' }} />
      <Box sx={{ overflow: 'auto', mt: 2 }}>
        <List>
          {menuItems.map((item) => (
            <ListItem button key={item.text} onClick={() => navigate(item.path)}>
              <ListItemIcon sx={{ color: 'white' }}>{item.icon}</ListItemIcon>
              <ListItemText primary={item.text} />
            </ListItem>
          ))}
          <Divider sx={{ my: 2, bgcolor: 'rgba(255,255,255,0.1)' }} />
          <ListItem button onClick={() => { logout(); navigate('/login'); }}>
            <ListItemIcon sx={{ color: 'white' }}><Logout /></ListItemIcon>
            <ListItemText primary="Logout" />
          </ListItem>
        </List>
      </Box>
    </Drawer>
  )
}

export default Sidebar
export { drawerWidth }
