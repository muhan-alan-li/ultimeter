import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
    plugins: [
        react(),
        VitePWA({
            registerType: 'prompt',
            includeAssets: ['icon.svg', 'icon-192.png', 'icon-512.png', 'apple-touch-icon.png'],
            manifest: {
                id: '/',
                name: 'Ultimeter',
                short_name: 'Ultimeter',
                description: 'Track your ultimate team, one point at a time.',
                start_url: '/teams',
                scope: '/',
                display: 'standalone',
                theme_color: '#f4efe6',
                background_color: '#f4efe6',
                icons: [
                    { src: '/icon-192.png', sizes: '192x192', type: 'image/png' },
                    {
                        src: '/icon-512.png',
                        sizes: '512x512',
                        type: 'image/png',
                        purpose: 'any maskable',
                    },
                ],
            },
            workbox: {
                globPatterns: ['**/*.{js,css,html,png,svg,webmanifest}'],
                navigateFallback: '/index.html',
            },
        }),
    ],
});
