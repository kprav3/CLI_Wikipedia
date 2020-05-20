import sys
import requests
import bs4

word = [] 

for i in range(1,len(sys.argv)-1):
	word.append(sys.argv[i])

s = "_".join(word)
keyword = (sys.argv[1:])
res = requests.get('https://en.wikipedia.org/wiki/Main_Page%s' % s)

res.raise_for_status()
#Just to raise the status code
wiki = bs4.BeautifulSoup(res.text,"lxml")
elems = wiki.select(['p','h'])
for i in range(len(elems)):
    article = elems[i].getText()
    print(article)
file_name = "_".join(keyword)
filesave =  file_name + ".txt"
with open(filesave, 'w') as file:
	file.write(article)
file.close()
print('Saved to %s' % filesave)