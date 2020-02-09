using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerCombat : MonoBehaviour
{
    public Animator animator;
    void Update()
    {
           if(Input.GetKeyDown(KeyCode.F))
           {
            Attack();
           }
    }


    void Attack()
    {
        animator.SetTrigger("Attack");
    }

}
