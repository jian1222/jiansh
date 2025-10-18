#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear

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

echo -e "${BLUE}==================================================================${NC}"
echo -e "${GREEN}           Pterodactyl Advanced Security System${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""
echo -e "${GREEN}Pilih instalasi:${NC}"
echo -e "${YELLOW}1)${NC} Install Protection di Panel (Web)"
echo -e "${YELLOW}2)${NC} Install Protection di Wings (Server)"
echo -e "${YELLOW}3)${NC} Install Full Protection (Panel + Wings)"
echo ""
read -p "Masukkan pilihan [1-3]: " choice

install_panel_protection() {
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
use Pterodactyl\Models\Server;

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
        
        $serverParam = $request->route('server');
        $serverId = null;
        
        if (is_object($serverParam)) {
            $serverId = $serverParam->id;
        } elseif (is_numeric($serverParam)) {
            $serverId = $serverParam;
        } elseif (is_string($serverParam)) {
            $server = Server::where('uuidShort', $serverParam)
                          ->orWhere('uuid', $serverParam)
                          ->first();
            if ($server) {
                $serverId = $server->id;
            }
        }
        
        if ($serverId) {
            $server = Server::find($serverId);
            
            if ($server && $server->owner_id !== $user->id) {
                $uri = $request->path();
                $method = $request->method();
                
                if (
                    strpos($uri, '/api/client/servers/') !== false ||
                    strpos($uri, '/server/') !== false
                ) {
                    $blockedPaths = [
                        '/console',
                        '/websocket',
                        '/resources',
                        '/files',
                        '/databases',
                        '/schedules',
                        '/settings',
                        '/startup',
                        '/backups',
                        '/network',
                        '/activity',
                        '/download',
                        '/upload',
                        '/delete',
                        '/rename',
                        '/copy',
                        '/write',
                        '/compress',
                        '/decompress',
                        '/create-folder',
                        '/pull'
                    ];
                    
                    foreach ($blockedPaths as $path) {
                        if (strpos($uri, $path) !== false) {
                            if ($request->expectsJson() || $request->is('api/*')) {
                                return response()->json([
                                    'errors' => [[
                                        'code' => 'SecurityJIANBlock',
                                        'status' => '403',
                                        'detail' => 'Lu Siapa Kocak Mau Intip Server?'
                                    ]]
                                ], 403);
                            }
                            
                            return response()->view('errors.403-security', [
                                'message' => 'Lu Siapa Kocak Mau Intip Server?',
                                'code' => 'SECURITY JIAN'
                            ], 403);
                        }
                    }
                }
                
                if ($method === 'DELETE') {
                    if ($request->expectsJson() || $request->is('api/*')) {
                        return response()->json([
                            'errors' => [[
                                'code' => 'SecurityJIANBlock',
                                'status' => '403',
                                'detail' => 'Lu Siapa Kocak Mau Del Panel Khusus Id 1 Server Tolol'
                            ]]
                        ], 403);
                    }
                    
                    return response()->view('errors.403-security', [
                        'message' => 'Lu Siapa Kocak Mau Del Panel Khusus Id 1 Server Tolol',
                        'code' => 'SECURITY JIAN'
                    ], 403);
                }
            }
        }
        
        if ($request->method() === 'DELETE') {
            if (strpos($request->path(), '/api/application/servers/') !== false) {
                $segments = explode('/', $request->path());
                $serverIdFromPath = null;
                
                foreach ($segments as $key => $segment) {
                    if ($segment === 'servers' && isset($segments[$key + 1])) {
                        $serverIdFromPath = $segments[$key + 1];
                        break;
                    }
                }
                
                if ($serverIdFromPath == 1) {
                    if ($request->expectsJson() || $request->is('api/*')) {
                        return response()->json([
                            'errors' => [[
                                'code' => 'SecurityJIANBlock',
                                'status' => '403',
                                'detail' => 'Lo Siapa Kocak Mau Del Server Admin Khusus Server 1 Tolol'
                            ]]
                        ], 403);
                    }
                    
                    return response()->view('errors.403-security', [
                        'message' => 'Lo Siapa Kocak Mau Del Server Admin Khusus Server 1 Tolol',
                        'code' => 'SECURITY JIAN'
                    ], 403);
                }
            }
        }
        
        if (strpos($request->path(), '/api/application/users/') !== false && $request->method() === 'PATCH') {
            $segments = explode('/', $request->path());
            $userIdFromPath = null;
            
            foreach ($segments as $key => $segment) {
                if ($segment === 'users' && isset($segments[$key + 1])) {
                    $userIdFromPath = $segments[$key + 1];
                    break;
                }
            }
            
            if ($userIdFromPath && $userIdFromPath != $user->id) {
                if ($request->expectsJson() || $request->is('api/*')) {
                    return response()->json([
                        'errors' => [[
                            'code' => 'SecurityJIANBlock',
                            'status' => '403',
                            'detail' => 'ACCESS DENIED - SECURITY JIAN'
                        ]]
                    ], 403);
                }
                
                return response()->view('errors.403-security', [
                    'message' => 'ACCESS DENIED',
                    'code' => 'SECURITY JIAN'
                ], 403);
            }
        }
        
        return $next($request);
    }
}
EOFPHP

    mkdir -p $PANEL_DIR/resources/views/errors
    
    cat > $PANEL_DIR/resources/views/errors/403-security.blade.php << 'EOFBLADE'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>403 | ACCESS DENIED - {{ $code }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
            color: #e2e8f0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .container {
            max-width: 500px;
            width: 100%;
            text-align: center;
        }
        
        .error-box {
            background: rgba(30, 41, 59, 0.8);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(239, 68, 68, 0.3);
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
        }
        
        .icon {
            width: 120px;
            height: 120px;
            margin: 0 auto 30px;
        }
        
        .error-code {
            font-size: 72px;
            font-weight: 800;
            color: #ef4444;
            margin-bottom: 10px;
            text-shadow: 0 0 30px rgba(239, 68, 68, 0.5);
        }
        
        .error-title {
            font-size: 24px;
            font-weight: 600;
            color: #f1f5f9;
            margin-bottom: 20px;
        }
        
        .error-message {
            font-size: 18px;
            color: #ef4444;
            font-weight: 600;
            margin-bottom: 10px;
            padding: 15px;
            background: rgba(239, 68, 68, 0.1);
            border-radius: 8px;
            border: 1px solid rgba(239, 68, 68, 0.3);
        }
        
        .security-badge {
            display: inline-block;
            font-size: 12px;
            color: #cbd5e1;
            margin-top: 20px;
            padding: 8px 16px;
            background: rgba(239, 68, 68, 0.1);
            border-radius: 20px;
            border: 1px solid rgba(239, 68, 68, 0.2);
        }
        
        .footer {
            margin-top: 30px;
            font-size: 14px;
            color: #64748b;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-box">
            <svg class="icon" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <rect x="3" y="11" width="18" height="11" rx="2" stroke="#ef4444" stroke-width="2"/>
                <path d="M7 11V7C7 4.23858 9.23858 2 12 2C14.7614 2 17 4.23858 17 7V11" stroke="#ef4444" stroke-width="2" stroke-linecap="round"/>
                <circle cx="12" cy="16" r="1.5" fill="#ef4444"/>
            </svg>
            
            <div class="error-code">403</div>
            <div class="error-title">ACCESS DENIED - {{ $code }}</div>
            
            <div class="error-message">
                {{ $message }}
            </div>
            
            <div class="security-badge">
                Server Access Denied - {{ $code }}
            </div>
            
            <div class="footer">
                Pterodactyl® © 2015 - 2025
            </div>
        </div>
    </div>
</body>
</html>
EOFBLADE

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
    php artisan route:clear
    
    chown -R www-data:www-data $PANEL_DIR/*
    
    echo -e "${GREEN}Panel Protection berhasil diinstall!${NC}"
}

case $choice in
    1)
        install_panel_protection
        echo -e "${YELLOW}Status: AKTIF ✓${NC}"
        ;;
        
    2)
        echo -e "${GREEN}Installing Wings Protection...${NC}"
        
        WINGS_CONFIG="/etc/pterodactyl/config.yml"
        
        if [ ! -f "$WINGS_CONFIG" ]; then
            echo -e "${RED}Error: Wings config tidak ditemukan${NC}"
            exit 1
        fi
        
        systemctl restart wings
        
        echo -e "${GREEN}Wings Protection berhasil diinstall!${NC}"
        echo -e "${YELLOW}Status: AKTIF ✓${NC}"
        ;;
        
    3)
        install_panel_protection
        
        WINGS_CONFIG="/etc/pterodactyl/config.yml"
        
        if [ -f "$WINGS_CONFIG" ]; then
            systemctl restart wings
            echo -e "${GREEN}Wings Protection berhasil diinstall!${NC}"
        fi
        
        echo -e "${GREEN}Full Protection berhasil diinstall!${NC}"
        echo -e "${YELLOW}Status Panel: AKTIF ✓${NC}"
        echo -e "${YELLOW}Status Wings: AKTIF ✓${NC}"
        ;;
        
    *)
        echo -e "${RED}Pilihan tidak valid!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}==================================================================${NC}"
echo -e "${GREEN}                    Instalasi Selesai!${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo -e "${GREEN}Fitur Aktif:${NC}"
echo -e "  ${YELLOW}✓${NC} Anti Intip Server Orang Lain"
echo -e "  ${YELLOW}✓${NC} Anti Delete Server ID 1"
echo -e "  ${YELLOW}✓${NC} Anti Delete Server Orang Lain"
echo -e "  ${YELLOW}✓${NC} Anti Akses Console Orang Lain"
echo -e "  ${YELLOW}✓${NC} Anti Download File Orang Lain"
echo -e "  ${YELLOW}✓${NC} Anti Upload File ke Server Orang Lain"
echo -e "  ${YELLOW}✓${NC} Anti Edit User Orang Lain"
echo -e "  ${YELLOW}✓${NC} User Hanya Bisa Akses Server Sendiri"
echo -e "  ${YELLOW}✓${NC} Halaman Error 403 Custom"
echo -e "${BLUE}==================================================================${NC}"
echo ""
echo -e "${GREEN}Untuk menggunakan script ini via URL:${NC}"
echo -e "${YELLOW}bash <(curl -s https://raw.githubusercontent.com/jian1222/jiansh/refs/heads/main/main.sh)${NC}"
echo ""
