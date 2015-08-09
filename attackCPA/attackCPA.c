#include <assert.h>
#include <limits.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include <libtraceio.h>
#include <libCPA.h>

#include <SBox_AES.h>

#define NB_WORDS 256

/**
 * @brief Computes the leakage prediction between a key byte
 *        hypothesis and a message byte
 *
 * @param N the size of both vectors
 * @param predictions first vector
 * @param leakages second vector
 *
 * @return the linear correlation coefficient
 */
static double prediction_func (uint8_t key_hyp, uint8_t msg)
{
  /* BEGIN Question 3 */
  /* ........ */
  /* END Question 3 */
  double result= 0;
  uint8_t index;
  char sbox_value;
  int i;

  index = key_hyp^msg;

  sbox_value = SBox_AES[index]; 

  for(i = 0; i < 8; i++){
     if( ((sbox_value>>i) & 0x01) == 0x01){
      result++;
    }
  }

  return result;
}

/**
 * @brief Computes the linear correlation coefficient between two
 *        vectors of size N
 *
 * @param N the size of both vectors
 * @param predictions first vector
 * @param leakages second vector
 *
 * @return the linear correlation coefficient
 */
static double linear_correlation (unsigned int N,
                                  double *predictions, double *leakages)
{
  /* BEGIN Question 4 */
  /* ........ */
  /* END Question 4 */
  unsigned int i = 0;
  double moyenne_predictions = 0;
  double moyenne_leakages = 0;
  double correlation = 0;
  double x, y = 0;
  double num = 0;
  double denum_x =0;
  double denum_y = 0;

  for(i = 0; i < N; i++){
    moyenne_predictions += predictions[i];
    moyenne_leakages += leakages[i];
  }

  moyenne_predictions = moyenne_predictions / N;
  moyenne_leakages = moyenne_leakages / N;

  //  printf("%lf \n",moyenne_predictions);
  // printf("%lf \n",moyenne_leakages);

  for(i = 0; i < N; i++){
    x = predictions[i] - moyenne_predictions;
    y = leakages[i] - moyenne_leakages;
    
    num += (x * y);

    denum_x += (x * x); 
    denum_y += (y * y);

  }

  denum_x = sqrt(denum_x);
  denum_y = sqrt(denum_y);

  //  printf("%lf \n",denum_x);
  // printf("%lf \n",denum_y);

  correlation = (num / (denum_x * denum_y));

  //rintf("\n %lf \n", correlation);

  return correlation;
}

/**
 * @brief Computes a CPA on a target data in a specified instant
 *
 * @param N number of traces 
 * @param trace_file_names array of `N` file names containing the traces
 * @param target_data the index of the key byte to target
 * @param target_cycle the instant to target (in cycles)
 * @param result_file_name name of the file to store the result
 *
 * @return 0 when no error occurred
 */
static int launch_CPA_etu (unsigned int N, char *trace_files_names[],
                           unsigned int target_data, unsigned int target_cycle,
                           char *result_file_name)
{
  unsigned int k;

  FILE *result_file;

  double *all_leakages;
  double *predictions;

  double correlations[NB_WORDS];
  uint8_t *msgs;
  
  uint8_t key = 0;

  unsigned int i;

  double argmax, max = -99999;

  /* allocate for predictions */
  predictions = calloc (N, sizeof (double));
  assert (predictions != NULL);

  /* allocate for leakages */
  all_leakages = calloc (N, sizeof (double));
  assert (all_leakages != NULL);

  /* allocate for msg bytes */
  msgs = calloc (N, sizeof (uint8_t));

  fprintf (stderr, "processing traces...      ");
  /* collect leakages:
     open each N trace file and read the correct msg byte and leakage */
  for (k = 0; k < N; k++)
    {
      FILE *trace_file;
      trace_container current_trace;

      trace_file = fopen (trace_files_names[k], "r");
      assert (trace_file != NULL);
      read_trace (trace_file, &current_trace);
      fclose (trace_file);

      /* store leakage */
      all_leakages[k] = current_trace.trace[target_cycle];

      /* get msg */
      msgs[k] = current_trace.input[target_data];

      free_trace (&current_trace);
    }
  fprintf (stderr, "done\n");

  fprintf (stderr, "computing correlations... ");
  /* compute correlations:
     for all NB_WORDS key hypotheses,
       - predict the leakage for each trace/message
       - compute the correlation between the predictions
         and the actual leakage
       - store it in the array `correlations` */
 
    /* BEGIN Question 5 */
    /* ........ */
    /* END Question 5 */

    for(k = 0; k < 256; k++){
      for(i = 0; i < N; i++){
	 predictions[i] = prediction_func( k, msgs[i]);  
      }
      correlations[k] = linear_correlation(N, predictions, all_leakages);
    }

  fprintf (stderr, "done\n");

  /* at this point, `correlations` contains the NB_WORDS correlation
     values for all key hypotheses */
  result_file = fopen (result_file_name, "w+");
  assert (result_file != NULL);
  write_CPA_result (result_file, correlations, NB_WORDS);
  fclose (result_file);

  free (all_leakages);
  free (msgs);

  return 0;
}

int main (int argc, char *argv[])
{
  unsigned int target_data;
  unsigned int target_cycle;

  if (argc < 4)
    {
      fprintf (stderr,
               "Usage: %s target_data target_cycle result_file traces...\n",
               argv[0]);
      return -1;
    }

  target_data = atoi (argv[1]);
  target_cycle = atoi (argv[2]);

  launch_CPA_etu (argc-4, argv+4, target_data, target_cycle, argv[3]);

  return 0;
}
