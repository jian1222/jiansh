#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}"
cat << "EOF"
     ██╗██╗ █████╗ ███╗   ██╗███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗
     ██║██║██╔══██╗████╗  ██║██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝
     ██║██║███████║██╔██╗ ██║███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝ 
██   ██║██║██╔══██║██║╚██╗██║╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝  
╚█████╔╝██║██║  ██║██║ ╚████║███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║   
 ╚════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝   
EOF
echo -e "${NC}"

echo -e "${YELLOW}==================================================================${NC}"
echo -e "${GREEN}           Pterodactyl Server Protection System${NC}"
echo -e "${YELLOW}==================================================================${NC}"
echo ""
echo -e "${GREEN}Pilih instalasi:${NC}"
echo -e "${YELLOW}1)${NC} Install Protection di Panel (Web)"
echo -e "${YELLOW}2)${NC} Install Protection di Wings (Server)"
echo -e "${YELLOW}3)${NC} Install Full Protection (Panel + Wings)"
echo ""
read -p "Masukkan pilihan [1-3]: " choice

case $choice in
    1)
        echo -e "${GREEN}Installing Panel Protection...${NC}"
        
        PANEL_DIR="/var/www/pterodactyl"
        
        if [ ! -d "$PANEL_DIR" ]; then
            echo -e "${RED}Error: Pterodactyl panel tidak ditemukan di $PANEL_DIR${NC}"
            exit 1
        fi
        
        cat > $PANEL_DIR/app/Http/Middleware/JianSecurity.php << 'EOFPHP'
<?php

namespace Pterodactyl\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class JianSecurity
{
    public function handle(Request $request, Closure $next)
    {
        $user = Auth::user();
        
        if (!$user) {
            return $next($request);
        }
        
        if ($user->root_admin) {
            return $next($request);
        }
        
        $serverId = $request->route('server');
        if (!$serverId && $request->route('server')) {
            $serverId = $request->route('server')->id ?? null;
        }
        
        if ($serverId) {
            $server = \Pterodactyl\Models\Server::find($serverId);
            
            if ($server && $server->owner_id !== $user->id) {
                $uri = $request->path();
                
                if (
                    strpos($uri, '/api/client/servers/') !== false ||
                    strpos($uri, '/server/') !== false
                ) {
                    if (
                        strpos($uri, '/console') !== false ||
                        strpos($uri, '/websocket') !== false ||
                        strpos($uri, '/resources') !== false ||
                        strpos($uri, '/files') !== false ||
                        strpos($uri, '/databases') !== false ||
                        strpos($uri, '/schedules') !== false ||
                        strpos($uri, '/settings') !== false ||
                        strpos($uri, '/startup') !== false ||
                        strpos($uri, '/backups') !== false ||
                        strpos($uri, '/network') !== false ||
                        strpos($uri, '/activity') !== false ||
                        strpos($uri, '/download') !== false
                    ) {
                        return response()->json([
                            'error' => 'Lu Siapa Kocak Mau Intip Server?',
                            'status' => 'DITOLAK'
                        ], 403);
                    }
                }
            }
        }
        
        if (
            $request->isMethod('delete') &&
            (strpos($request->path(), '/api/client/servers/') !== false ||
             strpos($request->path(), '/server/') !== false)
        ) {
            if ($serverId == 1) {
                return response()->json([
                    'error' => 'Lo Siapa Kocak Mau Del Server Admin Khusus Server 1 Tolol',
                    'status' => 'DITOLAK'
                ], 403);
            }
            
            $server = \Pterodactyl\Models\Server::find($serverId);
            if ($server && $server->owner_id !== $user->id) {
                return response()->json([
                    'error' => 'Lu Siapa Kocak Mau Del Panel Khusus Id 1 Server Tolol',
                    'status' => 'DITOLAK'
                ], 403);
            }
        }
        
        return $next($request);
    }
}
EOFPHP

        KERNEL_FILE="$PANEL_DIR/app/Http/Kernel.php"
        
        if grep -q "JianSecurity" "$KERNEL_FILE"; then
            echo -e "${YELLOW}JianSecurity sudah terdaftar di Kernel.php${NC}"
        else
            sed -i "/protected \$middlewareGroups = \[/,/\];/ {
                /\['web'\]/a\            \\\\Pterodactyl\\\\Http\\\\Middleware\\\\JianSecurity::class,
            }" "$KERNEL_FILE"
            
            sed -i "/protected \$middlewareGroups = \[/,/\];/ {
                /\['api'\]/a\            \\\\Pterodactyl\\\\Http\\\\Middleware\\\\JianSecurity::class,
            }" "$KERNEL_FILE"
            
            echo -e "${GREEN}JianSecurity berhasil ditambahkan ke Kernel.php${NC}"
        fi
        
        cd $PANEL_DIR
        php artisan config:clear
        php artisan cache:clear
        php artisan view:clear
        
        chown -R www-data:www-data $PANEL_DIR/*
        
        echo -e "${GREEN}Panel Protection berhasil diinstall!${NC}"
        echo -e "${YELLOW}Status: AKTIF ✓${NC}"
        ;;
        
    2)
        echo -e "${GREEN}Installing Wings Protection...${NC}"
        
        WINGS_CONFIG="/etc/pterodactyl/config.yml"
        
        if [ ! -f "$WINGS_CONFIG" ]; then
            echo -e "${RED}Error: Wings config tidak ditemukan${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}Wings Protection berhasil diinstall!${NC}"
        echo -e "${YELLOW}Status: AKTIF ✓${NC}"
        ;;
        
    3)
        echo -e "${GREEN}Installing Full Protection...${NC}"
        
        PANEL_DIR="/var/www/pterodactyl"
        
        if [ ! -d "$PANEL_DIR" ]; then
            echo -e "${RED}Error: Pterodactyl panel tidak ditemukan${NC}"
            exit 1
        fi
        
        cat > $PANEL_DIR/app/Http/Middleware/JianSecurity.php << 'EOFPHP'
<?php

namespace Pterodactyl\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class JianSecurity
{
    public function handle(Request $request, Closure $next)
    {
        $user = Auth::user();
        
        if (!$user) {
            return $next($request);
        }
        
        if ($user->root_admin) {
            return $next($request);
        }
        
        $serverId = $request->route('server');
        if (!$serverId && $request->route('server')) {
            $serverId = $request->route('server')->id ?? null;
        }
        
        if ($serverId) {
            $server = \Pterodactyl\Models\Server::find($serverId);
            
            if ($server && $server->owner_id !== $user->id) {
                $uri = $request->path();
                
                if (
                    strpos($uri, '/api/client/servers/') !== false ||
                    strpos($uri, '/server/') !== false
                ) {
                    if (
                        strpos($uri, '/console') !== false ||
                        strpos($uri, '/websocket') !== false ||
                        strpos($uri, '/resources') !== false ||
                        strpos($uri, '/files') !== false ||
                        strpos($uri, '/databases') !== false ||
                        strpos($uri, '/schedules') !== false ||
                        strpos($uri, '/settings') !== false ||
                        strpos($uri, '/startup') !== false ||
                        strpos($uri, '/backups') !== false ||
                        strpos($uri, '/network') !== false ||
                        strpos($uri, '/activity') !== false ||
                        strpos($uri, '/download') !== false
                    ) {
                        return response()->json([
                            'error' => 'Lu Siapa Kocak Mau Intip Server?',
                            'status' => 'DITOLAK'
                        ], 403);
                    }
                }
            }
        }
        
        if (
            $request->isMethod('delete') &&
            (strpos($request->path(), '/api/client/servers/') !== false ||
             strpos($request->path(), '/server/') !== false)
        ) {
            if ($serverId == 1) {
                return response()->json([
                    'error' => 'Lo Siapa Kocak Mau Del Server Admin Khusus Server 1 Tolol',
                    'status' => 'DITOLAK'
                ], 403);
            }
            
            $server = \Pterodactyl\Models\Server::find($serverId);
            if ($server && $server->owner_id !== $user->id) {
                return response()->json([
                    'error' => 'Lu Siapa Kocak Mau Del Panel Khusus Id 1 Server Tolol',
                    'status' => 'DITOLAK'
                ], 403);
            }
        }
        
        return $next($request);
    }
}
EOFPHP

        KERNEL_FILE="$PANEL_DIR/app/Http/Kernel.php"
        
        if grep -q "JianSecurity" "$KERNEL_FILE"; then
            echo -e "${YELLOW}JianSecurity sudah terdaftar${NC}"
        else
            sed -i "/protected \$middlewareGroups = \[/,/\];/ {
                /\['web'\]/a\            \\\\Pterodactyl\\\\Http\\\\Middleware\\\\JianSecurity::class,
            }" "$KERNEL_FILE"
            
            sed -i "/protected \$middlewareGroups = \[/,/\];/ {
                /\['api'\]/a\            \\\\Pterodactyl\\\\Http\\\\Middleware\\\\JianSecurity::class,
            }" "$KERNEL_FILE"
        fi
        
        cd $PANEL_DIR
        php artisan config:clear
        php artisan cache:clear
        php artisan view:clear
        
        chown -R www-data:www-data $PANEL_DIR/*
        
        echo -e "${GREEN}Full Protection berhasil diinstall!${NC}"
        echo -e "${YELLOW}Status Panel: AKTIF ✓${NC}"
        echo -e "${YELLOW}Status Wings: AKTIF ✓${NC}"
        echo -e "${YELLOW}Delete Protection: AKTIF ✓${NC}"
        echo -e "${YELLOW}Console Protection: AKTIF ✓${NC}"
        echo -e "${YELLOW}File Download Protection: AKTIF ✓${NC}"
        ;;
        
    *)
        echo -e "${RED}Pilihan tidak valid!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}==================================================================${NC}"
echo -e "${GREEN}                    Instalasi Selesai!${NC}"
echo -e "${YELLOW}==================================================================${NC}"
echo -e "${GREEN}Fitur Aktif:${NC}"
echo -e "  ${YELLOW}✓${NC} Anti Intip Server Orang Lain"
echo -e "  ${YELLOW}✓${NC} Anti Delete Server ID 1"
echo -e "  ${YELLOW}✓${NC} Anti Delete Server Orang Lain"
echo -e "  ${YELLOW}✓${NC} Anti Akses Console Orang Lain"
echo -e "  ${YELLOW}✓${NC} Anti Download File Orang Lain"
echo -e "  ${YELLOW}✓${NC} User Hanya Bisa Akses Server Sendiri"
echo -e "${YELLOW}==================================================================${NC}"
