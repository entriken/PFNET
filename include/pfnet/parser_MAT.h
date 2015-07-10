/** @file parser_MAT.h
 *  @brief This file list the constants and routines associated with the MAT_Parser data structure.
 *
 * This file is part of PFNET.
 *
 * Copyright (c) 2015, Tomas Tinoco De Rubira.
 *
 * PFNET is released under the BSD 2-clause license.
 */

#ifndef __PARSER_MAT_HEADER__
#define __PARSER_MAT_HEADER__

#include <stdio.h>
#include <string.h>
#include "net.h"
#include "types.h"
#include "parser_CSV.h"

// Pi
#define PI 3.14159265359

// Buffer
#define MAT_PARSER_BUFFER_SIZE 1024

// State
#define MAT_PARSER_STATE_TOKEN -1
#define MAT_PARSER_STATE_TITLE 0
#define MAT_PARSER_STATE_BUS 1
#define MAT_PARSER_STATE_GEN 2
#define MAT_PARSER_STATE_BRANCH 3

// Defaults
#define MAT_PARSER_BASE_POWER 100

// Tokens
#define BUS_TOKEN  "BUS"
#define END_TOKEN  "END"
#define GEN_TOKEN  "GEN"
#define BRANCH_TOKEN "BRANCH"

// Bus types
#define MAT_BUS_TYPE_PQ 1
#define MAT_BUS_TYPE_PV 2
#define MAT_BUS_TYPE_SL 3
#define MAT_BUS_TYPE_IS 4

// Structs
typedef struct MAT_Bus MAT_Bus;
typedef struct MAT_Gen MAT_Gen;
typedef struct MAT_Branch MAT_Branch;
typedef struct MAT_Parser MAT_Parser;

// Prototypes
MAT_Parser* MAT_PARSER_new(void);
void MAT_PARSER_clear_token(MAT_Parser* parser);
void MAT_PARSER_read(MAT_Parser* parser, char* filename);
void MAT_PARSER_show(MAT_Parser* parser);
void MAT_PARSER_load(MAT_Parser* parser, Net* net);
void MAT_PARSER_del(MAT_Parser* parser);
BOOL MAT_PARSER_has_error(MAT_Parser* parser);
char* MAT_PARSER_get_error_string(MAT_Parser* parser);
void MAT_PARSER_callback_field(char* s, void* data);
void MAT_PARSER_callback_row(void* data);
void MAT_PARSER_parse_token_field(char* s, MAT_Parser* parser);
void MAT_PARSER_parse_token_row(MAT_Parser* parser);
void MAT_PARSER_parse_title_field(char* s, MAT_Parser* parser);
void MAT_PARSER_parse_title_row(MAT_Parser* parser);
void MAT_PARSER_parse_bus_field(char* s, MAT_Parser* parser);
void MAT_PARSER_parse_bus_row(MAT_Parser* parser);
void MAT_PARSER_parse_gen_field(char* s, MAT_Parser* parser);
void MAT_PARSER_parse_gen_row(MAT_Parser* parser);
void MAT_PARSER_parse_branch_field(char* s, MAT_Parser* parser);
void MAT_PARSER_parse_branch_row(MAT_Parser* parser);

#endif
