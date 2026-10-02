import type { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId: 'com.niranjan.deepwork',
  appName: 'Deepwork',
  webDir: 'dist',
  backgroundColor: '#0B0B0F',
  android: {
    // Keep app content clear of the status and navigation bars.
    adjustMarginsForEdgeToEdge: 'force',
  },
  plugins: {
    LocalNotifications: {
      smallIcon: 'ic_stat_deepwork',
      iconColor: '#7C7CFF',
    },
  },
}

export default config
