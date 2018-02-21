Dec 20 2017 00:00:02
Q
!UW.yye1fxo
ID: 03c2f4
127154
We won't telegraph our moves to the ENEMY.
We will however light a FIRE to flush them out.
Q



POST CHECKER
check posts on chans
add new posts to /posts.json
add new images to /images/
push images+posts to repository
build

BUILD
build index.html with posts.json
compress images
gzip index.html + new images
cp index.html + new images to s3


```
bin/post_checker.dart

find . -type f -name "*.jpg" -exec jpegoptim {} \;
find . -type f -name "*.png" -exec optipng {} \;


to_amazon($1) {
  gzip -9k $1
  aws s3 cp $1.gz s3://qanonposts.com/$1
  rm $1.gz
}
```


local development:
- js/css/html updates
- manual posts.json fixes

server updates:
- posts.json updates
- new images

on push:
- posts.json / index.html modified? => build index.html
- all new files to amazon