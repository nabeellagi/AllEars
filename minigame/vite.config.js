import { defineConfig } from "vite";
import { VitePWA } from 'vite-plugin-pwa';

const kaplayCongrats = () => {
    return {
        name: "vite-plugin-kaplay-hello",
        buildEnd() {
            const line =
                "---------------------------------------------------------";
            const msg = `🦖 Awesome pal! Send your game to us:\n\n💎 Discord: https://discord.com/invite/aQ6RuQm3TF \n💖 Donate to KAPLAY: https://opencollective.com/kaplay\n\ (you can disable this msg on vite.config)`;

            process.stdout.write(`\n${line}\n${msg}\n${line}\n`);
        },
    };
};

export default defineConfig({
    // index.html out file will start with a relative path for script
    base: "./",
    server: {
        port: 3001,
    },
    build: {
        // disable this for low bundle sizes
        sourcemap: true,
        rollupOptions: {
            output: {
                manualChunks: {
                    kaplay: ["kaplay"],
                },
            },
        },
    },
    plugins: [
        // Disable messages removing this line
        kaplayCongrats(),
        VitePWA({
        registerType: 'autoUpdate',
        workbox: {
            globPatterns: ['**/*.{js,css,html,png,svg,ogg,wav}'],
            maximumFileSizeToCacheInBytes: 6 * 1024 * 1024 // 6 MB
        },
        manifest: {
            name: 'Kaboom Pet Game',
            short_name: 'KaboomPet',
            theme_color: '#ffffff',
            icons: [
            {
                src: 'pwa-icon.png',
                sizes: '192x192',
                type: 'image/png'
            }
            ]
        }
        })
    ]
});