using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DigitalRuby.WeatherMaker
{
    public class WeatherMakerDemoAnimateMoveScript : MonoBehaviour
    {
        public Vector3 Start;
        public Vector3 End;
        public float Duration;

        private float elapsed;

        private void Update()
        {
            elapsed += Time.deltaTime;
            transform.position = Vector3.Lerp(Start, End, elapsed / Duration);
        }
    }
}