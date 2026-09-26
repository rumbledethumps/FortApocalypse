; Picocomputer reset entry

         .import CART_START

         .segment "STARTUP"
         JMP CART_START
