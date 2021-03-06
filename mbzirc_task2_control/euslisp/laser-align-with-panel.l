(load "package://valve_task/euslisp/laser-panel-detector.l")

(defun get-x-ave (index num)
  (let ((x-ave 0) (cntr 0))
       (while (< cntr (* 2 num))
         (setq x-ave (+ x-ave (getSingleXDist (+ (- index num) + cntr))))
         (incf cntr))
       (setq x-ave (/ x-ave (* 2 num)))
       x-ave))

(defun get-y-ave (index num)
  (let ((y-ave 0) (cntr 0))
       (while (< cntr (* 2 num))
         (setq y-ave (+ y-ave (getSingleYDist (+ (- index num) + cntr))))
         (incf cntr))
       (setq y-ave (/ y-ave (* 2 num)))
       y-ave))

(defun calc-panel-rotation ()
  (let (x-left y-left x-right y-right panel-rot)
    (setq x-left (get-x-ave (ceiling (* (/ (length ranges) 8) 3)) 3))
    (setq y-left (get-y-ave (ceiling (* (/ (length ranges) 8) 3)) 3))
    (setq x-right (get-x-ave (ceiling (* (/ (length ranges) 8) 5)) 3))
    (setq y-right (get-y-ave (ceiling (* (/ (length ranges) 8) 5)) 3))
    (setq panel-rot (atan (/ (- x-right x-left) (- y-right y-left))))
    panel-rot))

(defun laser-fit-rotation ()
  (ros::spin-once)
  (let (panel-rot)
    (setq panel-rot calc-panel-rotation)
    (move-base 0 panel-rot :use-ri t)))

(defun laser-fit-x-translation (target-x)
  (ros::spin-once)
  (let (panel-x)
    (setq panel-x (* (get-x-ave (/ (length ranges) 2) 3) 1000))
    (move-base (* (- panel-x target-x) 1000) 0 :use-ri t)))

(defun laser-fix-y-translation (target-y)
  (let (prev-x current-x (x-diff 0) (x-thre 0.3) (done nil))
    (ros::spin-once)
    (setq prev-x (get-x-ave (/ (length ranges) 2) 3))
    (while (not done)
      (detect-panel-move-base 0 -5 0 50)
      (ros::sleep)
      (ros::spin-once)
      (setq current-x (get-x-ave (/ (length ranges) 2) 3))
      (setq x-diff (abs (- currnent-x prev-x)))
      (setq prev-x current-x)
      (when (> x-diff x-thre)
        (detect-panel-move-base 0 0 0 50)
        (setq done t)))
    (move-base-side target-y :use-ri t)

(defun laser-fit-translation (target-x target-y)
  (laser-fit-y-translation target-y)
  (laser-fit-x-translation target-x))

(defun laser-align-with-panel (target-x target-y)
  (laser-fit-rotation)
  (laser-fit-translation target-x target-y)
  (move-base 0 (/ PI 2) :use-ri t)
  t)
