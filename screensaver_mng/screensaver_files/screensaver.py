#!/usr/bin/env python3
"""
Protetor de Tela - Otimizado para Raspberry Pi 2
Funciona em framebuffer ou X11 com baixo consumo de recursos
"""

import pygame
import math
import time
import random
import sys
import os
from enum import Enum
from dataclasses import dataclass
from typing import Tuple, List

# Configurações otimizadas para RPi 2
SCREEN_WIDTH = 720  # Resolução HD
SCREEN_HEIGHT = 576  # Resolução HD
FPS = 20  # Baixo FPS para economizar CPU
COLORS = {
    'BLACK': (0, 0, 0),
    'WHITE': (255, 255, 255),
    'GREEN': (0, 255, 0),
    'BLUE': (0, 100, 255),
    'RED': (255, 50, 50),
    'CYAN': (0, 255, 255),
    'YELLOW': (255, 255, 0),
    'PURPLE': (255, 0, 255)
}

class EffectType(Enum):
    BOUNCING = 1
    FADE = 2
    ORBITAL = 3
    MATRIX = 4
    WAVE = 5

@dataclass
class TextObject:
    x: float
    y: float
    dx: float
    dy: float
    alpha: int
    color: Tuple[int, int, int]
    angle: float
    scale: float

class ZagariScreensaver:
    def __init__(self):
        self.running = True
        self.current_effect = EffectType.BOUNCING
        self.effect_duration = 10000  # 10 segundos por efeito
        self.effect_start_time = 0
        self.text_objects = []
        self.font_size = 72
        
        # Inicializar pygame
        pygame.init()
        
        # Configurar display (tenta framebuffer primeiro)
        self.init_display()
        
        # Configurar fonte
        self.font = pygame.font.Font(None, self.font_size)
        self.text_surface = self.font.render("ZAGARI", True, COLORS['WHITE'])
        self.text_rect = self.text_surface.get_rect()
        
        # Clock para controle de FPS
        self.clock = pygame.time.Clock()
        
        # Inicializar primeiro efeito
        self.init_effect()
        
    def init_display(self):
        """Inicializa o display, preferencialmente framebuffer"""
        try:
            # Tenta usar framebuffer diretamente
            os.environ['SDL_FBDEV'] = '/dev/fb0'
            os.environ['SDL_VIDEODRIVER'] = 'fbcon'
            os.environ['SDL_NOMOUSE'] = '1'
            
            self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT), 
                                                pygame.FULLSCREEN | pygame.DOUBLEBUF, 16)
            print("Usando framebuffer direto")
        except:
            try:
                # Fallback para X11
                self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT), 
                                                    pygame.FULLSCREEN)
                print("Usando X11")
            except:
                # Fallback para janela (desenvolvimento)
                self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
                print("Usando modo janela")
        
        pygame.display.set_caption("Zagari Screensaver")
        pygame.mouse.set_visible(False)
    
    def init_effect(self):
        """Inicializa o efeito atual"""
        self.text_objects.clear()
        self.effect_start_time = pygame.time.get_ticks()
        
        if self.current_effect == EffectType.BOUNCING:
            self.init_bouncing_effect()
        elif self.current_effect == EffectType.FADE:
            self.init_fade_effect()
        elif self.current_effect == EffectType.ORBITAL:
            self.init_orbital_effect()
        elif self.current_effect == EffectType.MATRIX:
            self.init_matrix_effect()
        elif self.current_effect == EffectType.WAVE:
            self.init_wave_effect()
    
    def init_bouncing_effect(self):
        """Efeito de texto saltitante"""
        self.text_objects.append(TextObject(
            x=random.randint(0, SCREEN_WIDTH - self.text_rect.width),
            y=random.randint(0, SCREEN_HEIGHT - self.text_rect.height),
            dx=random.choice([-3, -2, 2, 3]),
            dy=random.choice([-3, -2, 2, 3]),
            alpha=255,
            color=random.choice(list(COLORS.values())),
            angle=0,
            scale=1.0
        ))
    
    def init_fade_effect(self):
        """Efeito de fade in/out"""
        self.text_objects.append(TextObject(
            x=(SCREEN_WIDTH - self.text_rect.width) // 2,
            y=(SCREEN_HEIGHT - self.text_rect.height) // 2,
            dx=0,
            dy=0,
            alpha=0,
            color=COLORS['CYAN'],
            angle=0,
            scale=1.0
        ))
    
    def init_orbital_effect(self):
        """Efeito orbital circular"""
        self.text_objects.append(TextObject(
            x=SCREEN_WIDTH // 2,
            y=SCREEN_HEIGHT // 2,
            dx=0,
            dy=0,
            alpha=255,
            color=COLORS['YELLOW'],
            angle=0,
            scale=1.0
        ))
    
    def init_matrix_effect(self):
        """Efeito matrix com múltiplas instâncias"""
        for i in range(5):
            self.text_objects.append(TextObject(
                x=random.randint(0, SCREEN_WIDTH),
                y=-100 - i * 100,
                dx=0,
                dy=1 + i * 0.5,
                alpha=255 - i * 40,
                color=COLORS['GREEN'],
                angle=0,
                scale=0.5 + i * 0.1
            ))
    
    def init_wave_effect(self):
        """Efeito de onda senoidal"""
        self.text_objects.append(TextObject(
            x=0,
            y=SCREEN_HEIGHT // 2,
            dx=2,
            dy=0,
            alpha=255,
            color=COLORS['PURPLE'],
            angle=0,
            scale=1.0
        ))
    
    def update_bouncing_effect(self, obj: TextObject):
        """Atualiza efeito bouncing"""
        obj.x += obj.dx
        obj.y += obj.dy
        
        # Colisão com bordas
        if obj.x <= 0 or obj.x >= SCREEN_WIDTH - self.text_rect.width:
            obj.dx *= -1
            obj.color = random.choice(list(COLORS.values()))
        if obj.y <= 0 or obj.y >= SCREEN_HEIGHT - self.text_rect.height:
            obj.dy *= -1
            obj.color = random.choice(list(COLORS.values()))
    
    def update_fade_effect(self, obj: TextObject):
        """Atualiza efeito fade"""
        time_factor = (pygame.time.get_ticks() - self.effect_start_time) / 1000.0
        obj.alpha = int(127 + 127 * math.sin(time_factor))
        
        # Mudança gradual de cor
        r = int(127 + 127 * math.sin(time_factor))
        g = int(127 + 127 * math.sin(time_factor + 2))
        b = int(127 + 127 * math.sin(time_factor + 4))
        obj.color = (r, g, b)
    
    def update_orbital_effect(self, obj: TextObject):
        """Atualiza efeito orbital"""
        time_factor = (pygame.time.get_ticks() - self.effect_start_time) / 1000.0
        radius = 150
        
        center_x = SCREEN_WIDTH // 2
        center_y = SCREEN_HEIGHT // 2
        
        obj.x = center_x + radius * math.cos(time_factor) - self.text_rect.width // 2
        obj.y = center_y + radius * math.sin(time_factor) - self.text_rect.height // 2
        
        # Rotação da cor
        r = int(127 + 127 * math.cos(time_factor))
        g = int(127 + 127 * math.cos(time_factor + 2))
        b = int(127 + 127 * math.cos(time_factor + 4))
        obj.color = (r, g, b)
    
    def update_matrix_effect(self, obj: TextObject):
        """Atualiza efeito matrix"""
        obj.y += obj.dy
        
        # Reset quando sai da tela
        if obj.y > SCREEN_HEIGHT + 100:
            obj.y = -100
            obj.x = random.randint(0, SCREEN_WIDTH)
            obj.alpha = 255
        
        # Fade conforme desce
        if obj.y > SCREEN_HEIGHT - 200:
            obj.alpha = max(0, obj.alpha - 5)
    
    def update_wave_effect(self, obj: TextObject):
        """Atualiza efeito wave"""
        obj.x += obj.dx
        time_factor = (pygame.time.get_ticks() - self.effect_start_time) / 1000.0
        
        # Movimento senoidal
        obj.y = SCREEN_HEIGHT // 2 + 100 * math.sin(time_factor * 2 + obj.x * 0.01)
        
        # Reset quando sai da tela
        if obj.x > SCREEN_WIDTH + self.text_rect.width:
            obj.x = -self.text_rect.width
        
        # Mudança de cor baseada na posição
        r = int(127 + 127 * math.sin(obj.x * 0.01))
        g = int(127 + 127 * math.sin(obj.x * 0.01 + 2))
        b = int(127 + 127 * math.sin(obj.x * 0.01 + 4))
        obj.color = (r, g, b)
    
    def update(self):
        """Atualiza o estado do screensaver"""
        current_time = pygame.time.get_ticks()
        
        # Troca de efeito
        if current_time - self.effect_start_time > self.effect_duration:
            effects = list(EffectType)
            current_index = effects.index(self.current_effect)
            self.current_effect = effects[(current_index + 1) % len(effects)]
            self.init_effect()
        
        # Atualiza objetos baseado no efeito atual
        for obj in self.text_objects:
            if self.current_effect == EffectType.BOUNCING:
                self.update_bouncing_effect(obj)
            elif self.current_effect == EffectType.FADE:
                self.update_fade_effect(obj)
            elif self.current_effect == EffectType.ORBITAL:
                self.update_orbital_effect(obj)
            elif self.current_effect == EffectType.MATRIX:
                self.update_matrix_effect(obj)
            elif self.current_effect == EffectType.WAVE:
                self.update_wave_effect(obj)
    
    def draw(self):
        """Desenha o screensaver"""
        self.screen.fill(COLORS['BLACK'])
        
        for obj in self.text_objects:
            # Criar surface com alpha
            text_surf = self.font.render("ZAGARI", True, obj.color)
            if obj.alpha < 255:
                text_surf.set_alpha(obj.alpha)
            
            # Aplicar escala se necessário
            if obj.scale != 1.0:
                new_size = (int(text_surf.get_width() * obj.scale), 
                           int(text_surf.get_height() * obj.scale))
                text_surf = pygame.transform.scale(text_surf, new_size)
            
            self.screen.blit(text_surf, (int(obj.x), int(obj.y)))
        
        pygame.display.flip()
    
    def handle_events(self):
        """Processa eventos"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE or event.key == pygame.K_q:
                    self.running = False
                elif event.key == pygame.K_SPACE:
                    # Troca efeito manualmente
                    effects = list(EffectType)
                    current_index = effects.index(self.current_effect)
                    self.current_effect = effects[(current_index + 1) % len(effects)]
                    self.init_effect()
    
    def run(self):
        """Loop principal"""
        print("Iniciando Zagari Screensaver...")
        print("Pressione ESC ou Q para sair")
        print("Pressione SPACE para trocar efeito")
        
        while self.running:
            self.handle_events()
            self.update()
            self.draw()
            self.clock.tick(FPS)
        
        pygame.quit()
        sys.exit()

def main():
    """Função principal"""
    try:
        screensaver = ZagariScreensaver()
        screensaver.run()
    except KeyboardInterrupt:
        print("\nSaindo...")
        pygame.quit()
        sys.exit()
    except Exception as e:
        print(f"Erro: {e}")
        pygame.quit()
        sys.exit(1)

if __name__ == "__main__":
    main()