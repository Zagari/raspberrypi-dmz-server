#!/usr/bin/env python3
"""
Configuração avançada para Screensaver
Personalize todos os aspectos do protetor de tela
"""

import os
from enum import Enum
from typing import Dict, List, Tuple

class RPiModel(Enum):
    """Modelos de Raspberry Pi para otimizações específicas"""
    PI_ZERO = "zero"
    PI_1 = "pi1"
    PI_2 = "pi2"
    PI_3 = "pi3"
    PI_4 = "pi4"
    OTHER = "other"

class DisplayMode(Enum):
    """Modos de display disponíveis"""
    FRAMEBUFFER = "framebuffer"
    X11_FULLSCREEN = "x11_fullscreen"
    X11_WINDOW = "x11_window"
    AUTO = "auto"

# =============================================================================
# CONFIGURAÇÕES BÁSICAS
# =============================================================================

# Modelo do Raspberry Pi (para otimizações automáticas)
RPI_MODEL = RPiModel.PI_2

# Configurações de display
DISPLAY_CONFIG = {
    # Resolução da tela
    "width": 720,
    "height": 576,
    
    # Modo de display
    "mode": DisplayMode.AUTO,
    
    # Profundidade de cor (16 ou 32 bits)
    "color_depth": 16,
    
    # Taxa de atualização (FPS)
    "fps": 20,
    
    # Usar double buffering
    "double_buffer": True,
    
    # Habilitar VSync
    "vsync": False,
}

# =============================================================================
# CONFIGURAÇÕES DE EFEITOS
# =============================================================================

# Duração de cada efeito (em milissegundos)
EFFECT_DURATION = 15000

# Configurações de texto
TEXT_CONFIG = {
    # Texto principal
    "text": "ZAGARI",
    
    # Tamanho da fonte
    "font_size": 72,
    
    # Fonte personalizada (None para usar padrão)
    "font_path": None,
    
    # Suavização de texto
    "antialiasing": True,
    
    # Outline/borda do texto
    "outline_width": 0,
    "outline_color": (0, 0, 0),
}

# Configurações específicas por efeito
EFFECT_CONFIG = {
    "bouncing": {
        "enabled": True,
        "speed_min": 2,
        "speed_max": 4,
        "color_change_on_bounce": True,
        "trails": False,
    },
    
    "fade": {
        "enabled": True,
        "fade_speed": 1.0,
        "color_cycle": True,
        "pulse_scale": False,
    },
    
    "orbital": {
        "enabled": True,
        "radius": 150,
        "speed": 1.0,
        "elliptical": False,
        "color_rotation": True,
    },
    
    "matrix": {
        "enabled": True,
        "object_count": 5,
        "speed_variation": 0.5,
        "fade_out": True,
        "random_positions": True,
    },
    
    "wave": {
        "enabled": True,
        "amplitude": 100,
        "frequency": 2.0,
        "speed": 2,
        "color_wave": True,
    },
}

# =============================================================================
# ESQUEMA DE CORES
# =============================================================================

# Cores disponíveis
COLORS = {
    # Cores básicas
    "BLACK": (0, 0, 0),
    "WHITE": (255, 255, 255),
    "RED": (255, 0, 0),
    "GREEN": (0, 255, 0),
    "BLUE": (0, 0, 255),
    "YELLOW": (255, 255, 0),
    "CYAN": (0, 255, 255),
    "MAGENTA": (255, 0, 255),
    
    # Cores personalizadas
    "NEON_GREEN": (57, 255, 20),
    "ELECTRIC_BLUE": (125, 249, 255),
    "HOT_PINK": (255, 20, 147),
    "LIME": (50, 205, 50),
    "ORANGE": (255, 165, 0),
    "PURPLE": (128, 0, 128),
    "GOLD": (255, 215, 0),
    "SILVER": (192, 192, 192),
    
    # Cores tema escuro
    "DARK_RED": (139, 0, 0),
    "DARK_GREEN": (0, 100, 0),
    "DARK_BLUE": (0, 0, 139),
    "DARK_ORANGE": (255, 140, 0),
    
    # Cores pastel
    "LIGHT_PINK": (255, 182, 193),
    "LIGHT_BLUE": (173, 216, 230),
    "LIGHT_GREEN": (144, 238, 144),
    "LIGHT_YELLOW": (255, 255, 224),
}

# Paletas de cores predefinidas
COLOR_PALETTES = {
    "default": ["WHITE", "GREEN", "BLUE", "RED", "CYAN", "YELLOW", "PURPLE"],
    "neon": ["NEON_GREEN", "ELECTRIC_BLUE", "HOT_PINK", "YELLOW", "CYAN"],
    "warm": ["RED", "ORANGE", "YELLOW", "HOT_PINK", "GOLD"],
    "cool": ["BLUE", "CYAN", "ELECTRIC_BLUE", "PURPLE", "SILVER"],
    "pastel": ["LIGHT_PINK", "LIGHT_BLUE", "LIGHT_GREEN", "LIGHT_YELLOW"],
    "dark": ["DARK_RED", "DARK_GREEN", "DARK_BLUE", "DARK_ORANGE"],
    "matrix": ["GREEN", "NEON_GREEN", "LIME"],
    "retro": ["MAGENTA", "CYAN", "YELLOW", "GREEN"],
}

# Paleta ativa
ACTIVE_PALETTE = "default"

# =============================================================================
# CONFIGURAÇÕES DE PERFORMANCE
# =============================================================================

# Otimizações automáticas baseadas no modelo do RPi
PERFORMANCE_CONFIG = {
    RPiModel.PI_ZERO: {
        "fps": 10,
        "font_size": 48,
        "max_objects": 3,
        "effects_enabled": ["bouncing", "fade"],
        "use_dirty_rects": True,
    },
    
    RPiModel.PI_1: {
        "fps": 15,
        "font_size": 56,
        "max_objects": 3,
        "effects_enabled": ["bouncing", "fade", "orbital"],
        "use_dirty_rects": True,
    },
    
    RPiModel.PI_2: {
        "fps": 20,
        "font_size": 72,
        "max_objects": 5,
        "effects_enabled": ["bouncing", "fade", "orbital", "matrix", "wave"],
        "use_dirty_rects": False,
    },
    
    RPiModel.PI_3: {
        "fps": 30,
        "font_size": 84,
        "max_objects": 7,
        "effects_enabled": ["bouncing", "fade", "orbital", "matrix", "wave"],
        "use_dirty_rects": False,
    },
    
    RPiModel.PI_4: {
        "fps": 60,
        "font_size": 96,
        "max_objects": 10,
        "effects_enabled": ["bouncing", "fade", "orbital", "matrix", "wave"],
        "use_dirty_rects": False,
    },
}

# =============================================================================
# CONFIGURAÇÕES DE ENERGIA
# =============================================================================

POWER_CONFIG = {
    # Tempo inativo antes de ativar screensaver (segundos)
    "idle_timeout": 300,
    
    # Tempo antes de desligar display (segundos, 0 = nunca)
    "display_off_timeout": 1800,
    
    # Reduzir FPS quando inativo
    "reduce_fps_when_idle": True,
    "idle_fps": 5,
    
    # Desligar CPU de efeitos complexos após tempo limite
    "simple_mode_timeout": 3600,
}

# =============================================================================
# CONFIGURAÇÕES DE INPUT
# =============================================================================

INPUT_CONFIG = {
    # Detectar atividade do mouse
    "detect_mouse": True,
    
    # Detectar atividade do teclado
    "detect_keyboard": True,
    
    # Teclas para sair
    "exit_keys": ["ESCAPE", "q", "Q"],
    
    # Tecla para trocar efeito
    "next_effect_key": "SPACE",
    
    # Tecla para trocar paleta de cores
    "next_palette_key": "c",
    
    # Sensibilidade do mouse (pixels para detectar movimento)
    "mouse_sensitivity": 5,
}

# =============================================================================
# CONFIGURAÇÕES DE LOG
# =============================================================================

LOG_CONFIG = {
    # Nível de log (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    "level": "INFO",
    
    # Arquivo de log
    "file": os.path.expanduser("~/screensaver/logs/screensaver.log"),
    
    # Tamanho máximo do arquivo de log (MB)
    "max_size_mb": 10,
    
    # Número de arquivos de backup
    "backup_count": 3,
    
    # Log para console também
    "console": True,
    
    # Log de performance
    "performance": False,
}

# =============================================================================
# CONFIGURAÇÕES AVANÇADAS
# =============================================================================

ADVANCED_CONFIG = {
    # Usar framebuffer diretamente quando possível
    "prefer_framebuffer": True,
    
    # Aplicar otimizações específicas do RPi
    "rpi_optimizations": True,
    
    # Usar sprites pré-renderizados
    "prerender_sprites": True,
    
    # Limitar uso de memória
    "memory_limit_mb": 64,
    
    # Intervalo de limpeza de memória (segundos)
    "gc_interval": 60,
    
    # Prioridade do processo (-20 a 19)
    "process_priority": 0,
    
    # Usar threading para efeitos
    "use_threading": False,
}

# =============================================================================
# CONFIGURAÇÕES ESPECÍFICAS DO SISTEMA
# =============================================================================

SYSTEM_CONFIG = {
    # Diretório de trabalho
    "work_dir": os.path.expanduser("~/zagari-screensaver"),
    
    # Diretório de cache
    "cache_dir": os.path.expanduser("~/zagari-screensaver/cache"),
    
    # Arquivo de estado
    "state_file": os.path.expanduser("~/zagari-screensaver/state.json"),
    
    # Comandos do sistema
    "display_off_cmd": "vcgencmd display_power 0",
    "display_on_cmd": "vcgencmd display_power 1",
    "cpu_temp_cmd": "vcgencmd measure_temp",
    
    # Variáveis de ambiente
    "env_vars": {
        "SDL_FBDEV": "/dev/fb0",
        "SDL_VIDEODRIVER": "fbcon",
        "SDL_NOMOUSE": "1",
    },
}

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

def get_current_config():
    """Retorna configuração atual baseada no modelo do RPi"""
    base_config = {
        "display": DISPLAY_CONFIG,
        "text": TEXT_CONFIG,
        "effects": EFFECT_CONFIG,
        "colors": COLORS,
        "color_palettes": COLOR_PALETTES,
        "power": POWER_CONFIG,
        "input": INPUT_CONFIG,
        "log": LOG_CONFIG,
        "advanced": ADVANCED_CONFIG,
        "system": SYSTEM_CONFIG,
    }
    
    # Aplicar otimizações do modelo específico
    if RPI_MODEL in PERFORMANCE_CONFIG:
        perf_config = PERFORMANCE_CONFIG[RPI_MODEL]
        base_config["display"]["fps"] = perf_config["fps"]
        base_config["text"]["font_size"] = perf_config["font_size"]
        base_config["advanced"]["max_objects"] = perf_config["max_objects"]
        base_config["advanced"]["use_dirty_rects"] = perf_config["use_dirty_rects"]
        
        # Desabilitar efeitos não suportados
        enabled_effects = perf_config["effects_enabled"]
        for effect in base_config["effects"]:
            if effect not in enabled_effects:
                base_config["effects"][effect]["enabled"] = False
    
    return base_config

def get_color_palette(palette_name=None):
    """Retorna paleta de cores ativa"""
    if palette_name is None:
        palette_name = ACTIVE_PALETTE
    
    if palette_name not in COLOR_PALETTES:
        palette_name = "default"
    
    return [COLORS[color_name] for color_name in COLOR_PALETTES[palette_name]]

def detect_rpi_model():
    """Detecta modelo do Raspberry Pi automaticamente"""
    try:
        with open("/proc/cpuinfo", "r") as f:
            cpuinfo = f.read()
        
        if "Pi Zero" in cpuinfo:
            return RPiModel.PI_ZERO
        elif "Pi 4" in cpuinfo:
            return RPiModel.PI_4
        elif "Pi 3" in cpuinfo:
            return RPiModel.PI_3
        elif "Pi 2" in cpuinfo:
            return RPiModel.PI_2
        elif "Pi 1" in cpuinfo or "Pi Model B" in cpuinfo:
            return RPiModel.PI_1
        else:
            return RPiModel.OTHER
    except:
        return RPiModel.OTHER

# Detectar modelo automaticamente se não especificado
if RPI_MODEL == RPiModel.OTHER:
    RPI_MODEL = detect_rpi_model()

# =============================================================================
# CONFIGURAÇÃO FINAL
# =============================================================================

# Configuração compilada final
CONFIG = get_current_config()

# Exportar configurações principais para fácil acesso
SCREEN_WIDTH = CONFIG["display"]["width"]
SCREEN_HEIGHT = CONFIG["display"]["height"]
FPS = CONFIG["display"]["fps"]
FONT_SIZE = CONFIG["text"]["font_size"]
TEXT = CONFIG["text"]["text"]

if __name__ == "__main__":
    print(f"Configuração para Raspberry Pi {RPI_MODEL.value}")
    print(f"Resolução: {SCREEN_WIDTH}x{SCREEN_HEIGHT}")
    print(f"FPS: {FPS}")
    print(f"Tamanho da fonte: {FONT_SIZE}")
    print(f"Efeitos habilitados: {[k for k, v in CONFIG['effects'].items() if v['enabled']]}")
    print(f"Paleta ativa: {ACTIVE_PALETTE}")
    print(f"Cores disponíveis: {list(get_color_palette())}")