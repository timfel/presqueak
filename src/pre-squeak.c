/***** BEGIN LICENSE BLOCK *****
 * The contents of this file are subject to the The MIT License.
 * Copyright (c) 2010 Tim Felgentreff
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ***** END LICENSE BLOCK *****/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>

#include "SDL.h"
#include "PDL.h"

#ifndef VNC
#define VNC "sdlvnc"
#endif

#ifndef SQUEAK
#define SQUEAK "squeak"
#endif

#ifndef EXEC
#define EXEC "pre-squeak"
#endif

int squeak_pid, vnc_pid;
SDL_Surface *Surface;

void termination_handler() {
  kill(squeak_pid, SIGKILL);
  kill(vnc_pid, SIGKILL);
}

int fork_out(char* program_path) {
  char *dir, *squeakvm, *vnc;

  dir      = (char*)(calloc(strlen(program_path) + 1, sizeof(char)));
  vnc      = (char*)(calloc(strlen(program_path) + strlen(VNC) + 1, sizeof(char)));
  squeakvm = (char*)(calloc(strlen(program_path) + strlen(SQUEAK) + 1, sizeof(char)));

  if (!(squeakvm && dir && vnc)) {
    printf("ERROR: No memory allocated");
    return 1;
  }

  strncpy(dir, program_path, strlen(program_path) - strlen(EXEC));
  dir[strlen(program_path) - strlen(EXEC) + 1] = '\0';

  strcpy(vnc, dir);
  strcat(vnc, VNC);

  strcpy(squeakvm, dir);
  strcat(squeakvm, SQUEAK);

  squeak_pid = fork();
  if (squeak_pid == -1) return 0;
  if (squeak_pid == 0) { // Child
    execl("/bin/sh", squeakvm, "-nodisplay", "/media/internal/squeak/squeak");
  }

  vnc_pid = fork();
  if (vnc_pid == -1) return 0;
  if (vnc_pid == 0) {
    execl(vnc, "-server", "127.0.0.1", "-port", "5900");
  }

  free(squeakvm);
  free(dir);
  free(vnc);
  return 1;
}

int main(int argc, char** argv) {
  // Initialize the SDL library with the Video subsystem
  SDL_Init(SDL_INIT_VIDEO | SDL_INIT_NOPARACHUTE);
  // start the PDL library
  PDL_Init(0);
  // Tell it to use OpenGL version 2.0
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
  // Set the video mode to full screen with OpenGL-ES support
  Surface = SDL_SetVideoMode(320, 480, 0, SDL_OPENGL);

  // Now fork the sub-processes
  if (!fork_out(argv[0])) {
    return 1; // Error while creating child processes
  }

  // Event descriptor
  SDL_Event Event;
  do {
    while (SDL_PollEvent(&Event)) {
      switch (Event.type) {
        // List of keys that have been pressed
        case SDL_KEYDOWN:
          switch (Event.key.keysym.sym) {
            // Escape forces us to quit the app
            // This is also sent when the user makes a back gesture
            case SDLK_ESCAPE:
              Event.type = SDL_QUIT;
              break;
            default:
              break;
          }
          break;
        default:
          break;
      }
    }
  } while (Event.type != SDL_QUIT);
  // We exit anytime we get a request to quit the app

  // Cleanupp
  PDL_Quit();
  SDL_Quit();
  termination_handler();
  return 0;
}
