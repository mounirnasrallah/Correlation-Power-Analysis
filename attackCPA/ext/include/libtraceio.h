#ifndef LIBTRACEIO_H
#define LIBTRACEIO_H

#include <stdio.h>
#include <stdint.h>

typedef struct
{
  uint8_t *input;
  unsigned int input_len;
  uint8_t *output;
  unsigned int output_len;
  double *trace;
  unsigned int ncy;
} trace_container;

int init_trace (trace_container *container, unsigned int trace_len,
                unsigned int input_len, unsigned int output_len);
int read_trace (FILE *trace_file, trace_container *container);
int write_trace (FILE *trace_file, trace_container *container);
void free_trace (trace_container *container);

#endif  /* LIBTRACEIO_H */
