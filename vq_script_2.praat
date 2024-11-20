form Variables
   sentence filename 
endform

# Constants
sex = 1
chunk = 1             ; Divide segment into 3 chunks
length = 0.005        ; Length of window for spectrogram
f1ref = 500           ; Reference F1 frequency for males
f2ref = 1485          ; Reference F2 frequency for males
f3ref = 2475          ; Reference F3 frequency for males
freqcost = 1          ; Frequency cost
bwcost = 1            ; Bandwidth cost
transcost = 1         ; Transition cost

# Initialize output variable with column titles
output$ = "time" + tab$ + "H1_H2" + tab$ + "H1_A1" + tab$ + "H1_A2" + tab$+ "H1_A3" + newline$

# Load the specified sound file:
Read from file... 'filename$'
soundname$ = selected$ ("Sound", 1)
sound = selected("Sound")

# Set parameters based on sex
maxf = 5000  ; Maximum frequency for formant calculation (male)
select 'sound'
begin = Get start time
end = Get end time
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
n_d = end - begin
for kounter from 1 to chunk
   n_seg = n_d / chunk
   n_md = begin + ((kounter - 1) * n_seg) + (n_seg / 2)

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
   spectrum_begin = begin + ((kounter - 1) * n_seg)
   spectrum_end = begin + (kounter * n_seg)
   Extract part... 'spectrum_begin' 'spectrum_end' Hanning 1 no
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

      # Calculate differences
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

   # Append result line
	spectrum_mid = ( spectrum_end + spectrum_begin ) /2
   output$ = output$ + string$(spectrum_mid) + tab$ + string$(h1mnh2) + tab$ + string$(h1mna1) + tab$ + string$(h1mna2) + tab$ + string$(h1mna3) + newline$
endfor

# Print all results at once
echo 'output$'
select all
Remove