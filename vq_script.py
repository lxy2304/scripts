from polyglotdb import CorpusContext
import os


corpus_name = 'tutorial-subset'
if __name__ == '__main__':

    with CorpusContext(corpus_name) as c:
        # c.reset_acoustics()
        # c.config.praat_path = os.environ.get("praat")
        # props = [('H1_H2', float), ('H1_A1', float), ('H1_A2', float), ('H1_A3', float)]
        # script_path = os.path.join(os.getcwd(), "vq_script_2.praat")
        # c.analyze_track_script('voice_quality', props, script_path, phone_class='vowel', file_type='vowel')
        # assert 'voice_quality' in c.hierarchy.acoustics
        # assert (c.discourse_has_acoustics('voice_quality', c.discourses[0]))
        q = c.query_graph(c.phone).filter(c.phone.subset == 'vowel')
        q = q.columns(c.phone.label, c.phone.begin, c.phone.end, c.phone.voice_quality.track)
        results = q.all()
        for r in results:
            print(r,r.track)