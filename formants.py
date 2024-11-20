from polyglotdb import CorpusContext
import os
import re

corpus_name = 'tutorial-subset'

if __name__ == '__main__':

    with CorpusContext(corpus_name) as g:
        g.reset_acoustics()
        g.config.praat_path = os.environ.get("praat")
        script_path = os.path.join(os.getcwd(), "formants.praat")
        props =  [('F1', float), ('F2', float), ('F3', float)]
        arguments = [0.01, 0.025, 5, 5500]
        g.analyze_track_script('formants_other', props, script_path, phone_class='vowel', file_type='vowel', arguments=arguments)
        assert 'formants_other' in g.hierarchy.acoustics

        assert (g.discourse_has_acoustics('formants_other', g.discourses[0]))
        q = g.query_graph(g.phone).filter(g.phone.label == 'AH0')
        q = q.columns(g.phone.begin, g.phone.end, g.phone.formants_other.track)
        results = q.all()

        assert (len(results) > 0)
        print(len(results))
        for r in results:
            # print(r.track)
            assert (len(r.track))

        g.reset_acoustic_measure('formants_other')
        assert not g.discourse_has_acoustics('formants_other', g.discourses[0])