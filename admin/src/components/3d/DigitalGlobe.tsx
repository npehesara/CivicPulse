import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { Sphere, MeshDistortMaterial } from '@react-three/drei';
import * as THREE from 'three';

export const DigitalGlobe: React.FC = () => {
  const meshRef = useRef<THREE.Mesh>(null);
  
  useFrame(({ clock }) => {
    if (meshRef.current) {
      meshRef.current.rotation.y = clock.getElapsedTime() * 0.05;
    }
  });

  return (
    <group>
      <ambientLight intensity={0.5} />
      <directionalLight position={[10, 10, 5]} intensity={1} color="#22D3EE" />
      <pointLight position={[-10, -10, -5]} intensity={0.5} color="#4F7CFF" />
      
      {/* Outer wireframe sphere */}
      <Sphere args={[2.2, 32, 32]}>
        <meshBasicMaterial color="#22D3EE" wireframe transparent opacity={0.15} />
      </Sphere>

      {/* Inner glowing sphere with slight distortion */}
      <Sphere ref={meshRef} args={[2, 64, 64]}>
        <MeshDistortMaterial 
          color="#0B1020"
          emissive="#0B1020"
          distort={0.2}
          speed={2}
          roughness={0.2}
          transparent
          opacity={0.8}
        />
      </Sphere>

      {/* Orbiting rings */}
      <mesh rotation={[Math.PI / 3, 0, 0]}>
        <ringGeometry args={[2.6, 2.62, 64]} />
        <meshBasicMaterial color="#4F7CFF" transparent opacity={0.3} side={THREE.DoubleSide} />
      </mesh>
      <mesh rotation={[-Math.PI / 4, Math.PI / 6, 0]}>
        <ringGeometry args={[3, 3.01, 64]} />
        <meshBasicMaterial color="#22D3EE" transparent opacity={0.2} side={THREE.DoubleSide} />
      </mesh>
    </group>
  );
};
