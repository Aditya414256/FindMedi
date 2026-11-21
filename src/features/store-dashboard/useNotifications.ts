import { useEffect, useRef, useState, useCallback } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../auth/useAuth';
import type { AppNotification } from '../../types/database';

// Sound for notification
const NOTIFICATION_SOUND_URL = 'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQQAAAAAAA==';

export function useNotifications() {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const [alertsEnabled, setAlertsEnabled] = useState(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  const { data: notifications = [] } = useQuery({
    queryKey: ['notifications'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', user!.id)
        .order('created_at', { ascending: false })
        .limit(50);
      if (error) throw error;
      return data as AppNotification[];
    },
    enabled: !!user,
    refetchInterval: 30000, // refetch every 30s as fallback
  });

  const unreadCount = notifications.filter(n => !n.read).length;

  const playSound = useCallback(() => {
    if (!alertsEnabled) return;
    try {
      if (!audioRef.current) {
        audioRef.current = new Audio(NOTIFICATION_SOUND_URL);
      }
      audioRef.current.play().catch(() => {});
    } catch {}
  }, [alertsEnabled]);

  const showBrowserNotification = useCallback((message: string) => {
    if (!alertsEnabled) return;
    if (Notification.permission === 'granted') {
      new Notification('FindMedicine', { body: message, icon: '/vite.svg' });
    }
  }, [alertsEnabled]);

  const enableAlerts = useCallback(async () => {
    setAlertsEnabled(true);
    if ('Notification' in window && Notification.permission === 'default') {
      await Notification.requestPermission();
    }
  }, []);

  const markAsRead = useCallback(async (notificationId: string) => {
    await supabase
      .from('notifications')
      .update({ read: true })
      .eq('id', notificationId);
    queryClient.invalidateQueries({ queryKey: ['notifications'] });
  }, [queryClient]);

  const markAllAsRead = useCallback(async () => {
    if (!user) return;
    await supabase
      .from('notifications')
      .update({ read: true })
      .eq('user_id', user.id)
      .eq('read', false);
    queryClient.invalidateQueries({ queryKey: ['notifications'] });
  }, [user, queryClient]);

  // Subscribe to realtime notifications
  useEffect(() => {
    if (!user) return;
    const channel = supabase
      .channel('notifications-realtime')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: `user_id=eq.${user.id}`,
      }, (payload) => {
        queryClient.invalidateQueries({ queryKey: ['notifications'] });
        const msg = (payload.new as AppNotification).message;
        playSound();
        showBrowserNotification(msg);
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [user, queryClient, playSound, showBrowserNotification]);

  return {
    notifications,
    unreadCount,
    alertsEnabled,
    enableAlerts,
    markAsRead,
    markAllAsRead,
  };
}
