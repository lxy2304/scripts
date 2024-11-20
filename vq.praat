form Analyze specific interval in a WAV file
   comment Full path to the sound file:
   text sound_file_path ~/Desktop/acoustic_corpus.wav
   comment Full path of the resulting text file:
   text resultfile ~/Desktop/output.txt
   comment Start time (in seconds):
   positive start_time 0
   comment End time (in seconds):
   positive end_time 1
   comment Divide segment into how many chunks:
   integer chunk 3
   comment Select sex of speaker:
   choice sex 1
   button male
   button female
   comment Length of window over which spectrogram is calculated:
   positive length 0.005
   comment Settings for Track... algorithm (MALE on the left; FEMALE on the right)
   positive left_F1_reference 500
   positive right_F1_reference 550
   positive left_F2_reference 1485
   positive right_F2_reference 1650
   positive left_F3_reference 2475
   positive right_F3_reference 2750
   positive left_Frequency_cost 1
   positive right_Frequency_cost 1
   positive left_Bandwidth_cost 1
   positive right_Bandwidth_cost 1
   positive left_Transition_cost 1
   positive right_Transition_cost 1
endform

# Check if the result file exists:
if fileReadable (resultfile$)
   pause The result file 'resultfile$' already exists! Do you want to overwrite it?
   filedelete 'resultfile$'
endif

# Write a row with column titles to the result file:
titleline$ = "Start	End	H1-H2 H1-A1 H1-A2 H1-A3"
fileappend "'resultfile$'" 'titleline$''newline$'

# Load the specified sound file:
Read from file... 'sound_file_path$'
soundname$ = selected$ ("Sound", 1)
sound = selected("Sound")

# Set maximum frequency of Formant calculation based on speaker sex
if sex = 1
   maxf = 5000
   f1ref = left_F1_reference
   f2ref = left_F2_reference
   f3ref = left_F3_reference
   freqcost = left_Frequency_cost
   bwcost = left_Bandwidth_cost
   transcost = left_Transition_cost
else
   maxf = 5500
   f1ref = right_F1_reference
   f2ref = right_F2_reference
   f3ref = right_F3_reference
   freqcost = right_Frequency_cost
   bwcost = right_Bandwidth_cost
   transcost = right_Transition_cost
endif

select 'sound'
Resample... 16000 50
sound_16khz = selected("Sound")
To Formant (burg)... 0.01 5 'maxf' 0.025 50
Rename... 'soundname$_beforetracking'
formant_beforetracking = selected("Formant")

xx = Get minimum number of formants
if xx > 2
   Track... 3 'f1ref' 'f2ref' 'f3ref' 3465 4455 'freqcost' 'bwcost' 'transcost'
else
   Track... 2 'f1ref' 'f2ref' 'f3ref' 3465 4455 'freqcost' 'bwcost' 'transcost'
endif

Rename... 'soundname$_aftertracking'
formant_aftertracking = selected("Formant")
select 'sound'
To Spectrogram... 'length' 4000 0.002 20 Gaussian
spectrogram = selected("Spectrogram")
select 'sound'
To Pitch... 0 60 350
pitch = selected("Pitch")
Interpolate
Rename... 'soundname$_interpolated'
pitch_interpolated = selected("Pitch")

# Divide the interval into chunks:
n_d = end_time - start_time
for kounter from 1 to chunk
   n_seg = n_d / chunk
   n_md = start_time + ((kounter - 1) * n_seg) + (n_seg / 2)

   # Get F1, F2, and F3 measurements
   select 'formant_aftertracking'
   f1hzpt = Get value at time... 1 n_md Hertz Linear
   f2hzpt = Get value at time... 2 n_md Hertz Linear
   if xx > 2
      f3hzpt = Get value at time... 3 n_md Hertz Linear
   else
      f3hzpt = 0
   endif

   # Extract sound for spectral analysis
   select 'sound_16khz'
   spectrum_begin = start_time + ((kounter - 1) * n_seg)
   spectrum_end = start_time + (kounter * n_seg)
   Extract part...  'spectrum_begin' 'spectrum_end' Hanning 1 no
   Rename... 'soundname$_slice'
   To Spectrum (fft)
   To Ltas (1-to-1)
   ltas = selected("Ltas")

   select 'pitch_interpolated'
   n_f0md = Get value at time... n_md Hertz Linear
   if n_f0md <> undefined
      # Calculate H1 and H2
      h1db = undefined
      h2db = undefined
      select 'ltas'
      lowerbh1 = n_f0md - (n_f0md / 10)
      upperbh1 = n_f0md + (n_f0md / 10)
      lowerbh2 = (n_f0md * 2) - ((n_f0md * 2) / 10)
      upperbh2 = (n_f0md * 2) + ((n_f0md * 2) / 10)
      h1db = Get maximum... lowerbh1 upperbh1 None
      h2db = Get maximum... lowerbh2 upperbh2 None
      if h1db = undefined
         h1db = 0
      endif
      if h2db = undefined
         h2db = 0
      endif

      # Calculate A1, A2, and A3
      a1db = undefined
      a2db = undefined
      a3db = undefined
      if f1hzpt <> undefined
         lowerba1 = f1hzpt - (f1hzpt / 10)
         upperba1 = f1hzpt + (f1hzpt / 10)
         a1db = Get maximum... lowerba1 upperba1 None
      endif
      if f2hzpt <> undefined
         lowerba2 = f2hzpt - (f2hzpt / 10)
         upperba2 = f2hzpt + (f2hzpt / 10)
         a2db = Get maximum... lowerba2 upperba2 None
      endif
      if f3hzpt <> undefined
         lowerba3 = f3hzpt - (f3hzpt / 10)
         upperba3 = f3hzpt + (f3hzpt / 10)
         a3db = Get maximum... lowerba3 upperba3 None
      endif
      if a1db = undefined
         a1db = 0
      endif
      if a2db = undefined
         a2db = 0
      endif
      if a3db = undefined
         a3db = 0
      endif

      # Calculate H1-A1, H1-A2, H1-A3
      h1mnh2 = h1db - h2db
      h1mna1 = h1db - a1db
      h1mna2 = h1db - a2db
      h1mna3 = h1db - a3db
   else
      h1mnh2 = 0
      h1mna1 = 0
      h1mna2 = 0
      h1mna3 = 0
   endif

   resultline$ = "'spectrum_begin'	 'spectrum_end'	'h1mnh2'	'h1mna1'	'h1mna2'	'h1mna3'	"
   fileappend "'resultfile$'" 'resultline$' 'newline$'
endfor

resultline$ = "'newline$'"
fileappend "'resultfile$'" 'resultline$'

select all
Remove
