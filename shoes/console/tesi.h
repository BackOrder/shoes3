#ifndef TESI_H
#define TESI_H

// _XOPEN_SOURCE for posix_openpt() from stdlin and fcntl
#define _XOPEN_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/types.h>

#if defined(SHOES_QUARTZ)
#define HALF_PTY 
#elif defined(SHOES_GTK_WIN32)
#define NO_PTY
#else
#define USE_PTY
#endif

#if defined(SHOES_QUARTZ) || defined(SHOES_GTK_OSX)
#include <util.h>
#elif !defined(NO_PTY)
#include <pty.h>
extern int posix_openpt(int);   // shut warnings off
extern int setenv(const char*, const char*, int); // shut warnings off
#endif
#if !defined(NO_PTY)
#include <utmp.h>
#include <unistd.h>
#include <string.h>
#include <poll.h>
#include <signal.h>
#endif

#ifndef false
#define false 0
#endif
#ifndef true
#define true 1
#endif

#define TESI_OUTPUT_BUFFER_LENGTH 128

struct tesiObject; // forward declare for C compilier

struct tesiObject {
	// file descriptor for  "select"ing whether there are terminal sequences to be processed
	int fd_activity;
	int fd_input;
	int partialSequence; // whether we've begun buffering an escape sequence
	char *sequence; // escape sequence buffer
	int sequenceLength;
	//char outputBuffer[129];
	//int outputBufferLength;
	void *pointer; // *gtk_text_view or *NSTextView

	int parameters[32];
	int parametersLength;
	char attributes[8]; // display attributes: bold, foreground, etc
	int insertMode;

	pid_t pid;
	int ptyMaster;
	int ptySlave;
	char *command[3];

	void (*callback_haveCharacter)(struct tesiObject *, char); // No longer used???
	void (*callback_printCharacter)(struct tesiObject *, char, int, int); // print character at x, y
  void (*callback_handleRTN)(struct tesiObject *, int, int); 
  void (*callback_handleNL)(struct tesiObject *, int, int);
  void (*callback_handleBS)(struct tesiObject *, int, int);
  void (*callback_handleBEL)(struct tesiObject *, int, int);
  void (*callback_handleTAB)(struct tesiObject *, int, int);
	void (*callback_printString)(void*, char*, int, int, int); // print string of length at x, y
  
  void (*callback_attreset)(struct tesiObject *);  // reset all attributes
  void (*callback_charattr)(struct tesiObject *, int);  // char based attributes 1..27
  void (*callback_setbgcolor)(struct tesiObject *, int);  // attr 40..47
  void (*callback_setfgcolor)(struct tesiObject *, int); // set text color attribute 30..37
  void (*callback_setfg256)(struct tesiObject *, int); // 38;5;x
  void (*callback_setbg256)(struct tesiObject *, int); // 48;5;x
  void (*callback_setdefcolor)(struct tesiObject *, int); // 39,49 set default color
    // cursor based callbacks - caution - maybe not be implemented 
    // and probably don't do what you think should be done.
	void (*callback_eraseLine)(struct tesiObject *, int, int, int); // erase line at from_x, to_x, line y
 	void (*callback_moveCursor)(struct tesiObject *, int, int); // move to x, y 
  void (*callback_deleteLines) (struct tesiObject *, int);  // delete is not erase
 	void (*callback_insertLines)(struct tesiObject *, int); // insert lines at lines
   
	void (*callback_clearScreen)(struct tesiObject *, int scrollback); // 
  
	void (*callback_insertCharacter)(struct tesiObject *, char, int, int); // insert character at x, y

	void (*callback_eraseCharacter)(struct tesiObject *, int, int); // erase character at x, y
	void (*callback_attributes)(struct tesiObject *, short, short, short, short, short, short, short); // bold, blink, inverse, underline, foreground, background, charset
	void (*callback_scrollRegion)(struct tesiObject *,int,int);
	void (*callback_scrollUp)(struct tesiObject *);
	void (*callback_scrollDown)(struct tesiObject *);
	void (*callback_invertColors)(struct tesiObject *);
#if defined(USE_PTY) || defined(NO_PTY)  // Linux and Windows gtk
  void (*callback_rawCapture) (struct tesiObject *, char *, int);
#endif
#ifdef NO_PTY
  void *win_bridge;
#endif
  unsigned int ides; // event source id from g_timeout_add
	int x, y, x2, y2, width, height, scrollBegin, scrollEnd; // cursor x,y and window width,height
	//int alternativeChar;
};

int tesi_handleControlCharacter(struct tesiObject*, char);
void tesi_interpretSequence(struct tesiObject*);
// limit cursor to terminal boundaries. return 1 if cursor out of bounds
// set second param to 1 to invoke moveCursor callback whether or not cursor is out of bounds
int tesi_limitCursor(struct tesiObject*, int);
void tesi_processAttributes(struct tesiObject*, int, int);
struct tesiObject* newTesiObject(char*, int, int);
void deleteTesiObject(void*);
#if defined(USE_PTY) 
int tesi_handleInput(struct tesiObject*);
#else
int tesi_handleInput(struct tesiObject*, char *, int);
#endif
#ifdef NO_PTY // gtk3/windows 
extern int setenv(const char *, const char *, int);
#endif

#endif //TESI_H
