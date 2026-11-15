File.open('movie-started.txt','w'){|f|f.write('STARTED')}
Graphics.play_movie('movie-reference.ogv')
File.open('movie-ended.txt','w'){|f|f.write('ENDED')}
exit
