# ni-pack for xyzzy

����͉�
--------
xyzzy�̊g��Lisp��Git���|�W�g������NetInstaller�����ɔz�z�ł���悤�ɂ����B


�ˑ����郉�C�u����
------------------
- [ansify](https://github.com/bowbow99/xyzzy.ansify)

���̑��ɕK�v�Ȃ���
------------------
- Git for Windows


�C���X�g�[��
------------
TODO: �z�z�ł���悤�ɂ����珑��


�����Ɛݒ�
----------
���[�J���Ɉȉ��̂��̂�p�ӂ���K�v������܂��B

- ���[�J���T�C�g
  - SITE-DIR: �z�z����u���f�B���N�g��
  - SITE-FILE: �z�z�����X�g�t�@�C���i`packages.l`�j
- �g���� Git ���|�W�g��
  - ���|�W�g���̃��[�g���炻�̂܂� zip �Ōł߂���悤�ɔz�u����
  - ���[�g�� `README.md`
    - ���̑��̃t�@�C�����܂߂āA���[�g�����ɂ���t�@�C���� `site-lisp/<�g����>/` �Ɉړ������
  - lisp �t�@�C���� `./site-lisp/` �ȉ��ɒu��
  - MAIN-SOURCE: ���C���� lisp �t�@�C�� `./site-lisp/<�g����>.l`
    - TODO: �w�b�_�̏�����

`SITE-FILE` �͖������ `ni-pack::create-local-site` �ō쐬���邱�Ƃ��ł��܂��B


��L���p�ӏo������A`.xyzzy` �Ȃǂ�

    (require "ni-pack")
    (setf ni-pack:*local-site-directory* "~/path/to/SITE-DIR")

���ɐݒ�ł��鍀�ڂ͈ȉ��̂��̂�����܂��B

- `ni-pack:*local-site-file*`
  - �ݒ肵�Ȃ���� `<SITE-DIR>/packages.l` �ɂȂ�܂��B
  - ����ȊO�̃t�@�C�����g�p����ꍇ�́A���̃t�@�C���̃p�X��ݒ肵�Ă��������B
- `ni-pack:*site-base-url*`
  - �z�z����u���f�B���N�g����URL�ł��B�e�z�z�����_�E�����[�h����URL�Ɏg�p����܂��B
  - �ݒ肵�Ȃ���΃T�C�g�� URL ���g�p����܂��B
  - ����ȊO�̏ꏊ�ɔz�z����u���ꍇ�́A���� URL ���w�肵�܂��B
- `ni-pack:*temp-directory*`
  - �z�z�����쐬����ۂɎd�l����ꎞ�f�B���N�g���ł��B
  - �w�肵�Ȃ���΁A���ϐ� `TMP` ���g�p����܂��B


�g����
------

1. �g�������
  - Git�ŊǗ����Ă�������
  - �����[�X�ł����Ԃɂ��Ă�������
2. `M-x ni-pack:release`
  - �t�@�C�����𕷂����̂ŁA<MAIN-SOURCE> ���w�肵�܂��B
  - �������茾���ƈȉ��̂悤�ɏ�������܂�
    - ���|�W�g�����ꎞ�f�B���N�g���ɃN���[������ `.git` �����폜
    - ���[�g�����ɂ���t�@�C���� `site-lisp/<�g����>/` �ֈړ�
    - lisp�t�@�C����S�ăR���p�C��
    - zip �Ōł߂� `<SITE-DIR>/<�g����>-<�o�[�W����>.zip` ���쐬
    - <SITE-FILE> ���X�V
3. ���J�ꏊ�փA�b�v���[�h���Ă�������


���C�Z���X
----------
[MIT](COPYING.mit)
